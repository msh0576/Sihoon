/*
 * Copyright (c) 2006 Stanford University.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the
 *   distribution.
 * - Neither the name of the Stanford University nor the names of
 *   its contributors may be used to endorse or promote products derived
 *   from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL STANFORD
 * UNIVERSITY OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
 * INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */
/**
 * @author Philip Levis
 */

/**
 * The configuration that takes an underlying software SPI on Mulle 
 * and turns it into a shared abstraction.
 *
 * @author Henrik Makitaavola
 */

generic module SoftSpiMasterImplP()
{
  provides interface Resource[uint8_t client];
  provides interface SpiPacket[uint8_t client];
  provides interface SpiByte[uint8_t client];
  uses interface Resource as SubResource[uint8_t];
  uses interface SpiPacket as SubPacket;
  uses interface SpiByte as SubByte;
}
implementation
{

  enum
  {
    NO_CLIENT = 0xff
  };
  
  uint8_t currentClient = NO_CLIENT;

  async command error_t Resource.request[uint8_t id]()
  {
    return call SubResource.request[id]();
  }

  async command error_t Resource.immediateRequest[uint8_t id]()
  {
    error_t rval = call SubResource.immediateRequest[id]();
    if (rval == SUCCESS)
    {
      atomic currentClient = id;
    }
    return rval;
  }

  event void SubResource.granted[uint8_t id]()
  {
    atomic currentClient = id;
    signal Resource.granted[id]();
  }

  async command error_t Resource.release[uint8_t id]()
  {
    return call SubResource.release[id]();
  }

  async command bool Resource.isOwner[uint8_t id]()
  {
    return call SubResource.isOwner[id]();
  }
  
  async command uint8_t SpiByte.write[uint8_t id](uint8_t tx)
  {
    atomic
    {
      if (currentClient != id)
      {
	return FAIL;
      }
    }
    return call SubByte.write(tx);
  }

  async command error_t SpiPacket.send[uint8_t id](uint8_t* txBuf,
                                                   uint8_t* rxBuf,
                                                   uint16_t len )
  {
    atomic
    {
      if (currentClient != id)
      {
	return FAIL;
      }
    }
    return call SubPacket.send(txBuf, rxBuf, len);
  }

  async event void SubPacket.sendDone(uint8_t* txBuf,
                                     uint8_t* rxBuf,
                                     uint16_t len,
                                     error_t error )
  {
    signal SpiPacket.sendDone[currentClient](txBuf, rxBuf, len, error);
  }

  default async event void SpiPacket.sendDone[uint8_t id](uint8_t* txBuf,
                                           uint8_t* rxBuf,
                                           uint16_t len,
                                           error_t error) {}

  default event void Resource.granted[uint8_t id]() {}


}

