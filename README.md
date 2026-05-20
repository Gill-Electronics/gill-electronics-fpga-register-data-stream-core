# gill-electronics-fpga-register-data-stream-core
Custom IP core that allows the client to write to and read from a set of registers while the FPGA streams data to the client

## Motivation
I want to create a sonar that only uses an FPGA, no embedded processor. So I need a way to control that sonar and receive data streaming from it. I could make the control interface specific to that sonar. Or I could make it more of a generic embedded device control interface where you write to and read from a set of registers. So that is what this core is. A way to command and control an FPGA in a fairly generic way. And we will go about the design of it with my sonar in mind so that it has all the features needed for that because there may be a few specific features that a generic device wouldn't need and I want to make sure we have them.

## Sonar Requirements = 63 bytes
- State Bits = 8 bits (1 byte)
  - Control whether the sonar is in sleep or wake mode = 1 bit
  - Control whether the sonar is running or idle = 1 bit
  - Control whether the sonar is transmitting or receiving only = 1 bit
  - Control whether we are using an internal ping generator or taking in an external ping = 1 bit
  - Control whether that external ping is coming in via hardware trigger or control message = 1 bit
- Ping rate = 32 bits (4 bytes)
- Data mode: real data, test patterns, or various processing modes = 8 bits (1 byte)
- Pulse width frequency 1 = 32 bits (4 bytes)
- Bandwidth frequency 1 = 32 bits (4 bytes)
- Center frequency frequency 1 = 32 bits (4 bytes)
- Pulse width frequency 2 = 32 bits (4 bytes)
- Bandwidth frequency 2 = 32 bits (4 bytes)
- Center frequency frequency 2 = 32 bits (4 bytes)
- Ping number = 32 bits (4 bytes)
- Sample number = 32 bits (4 bytes)
- Time = 64 bits (8 bytes)
- Version = 8 bits (1 byte)
- IMU / temperature / auxillary data = 128 bits (16 bytes)
- Ability to send trigger message to sonarvia command and control
- Ability to set time via command and control or hardware trigger
- Ability to write new coefficients to filter or write arbitrary waveform to tx (need a chunk of memory)

## Register Data Stream Core Requirements
- 16 writeable registers that are 32 bits long (registers 0 - 15)
- 16 read only registers that are 32 bits long (registers 16 - 31)
- Client can send message to write one register
- Server responds to write one register request
- Client can send message to write all registers
- Server responds to write all register request
- Client can send message to read one register
- Server responds to read one register request
- Client can send message to read all registers
- Server responds to read all register request
- Client can send message indicating trigger pulse
- Server responds to trigger request
- Client can write to a large chunk of memory = size TBD
- Core will raise a flag when registers are written to in case fpga is implementing a state machine based on the contents. This flag can then be cleared by the fpga
- FPGA can stream data or other messages into the core and the core will interleave them into its own stream out, always prioritizing its own stream while fifoing the secondary stream
- Client side interface will be 1 byte wide axi stream using tlast to indicate the end of a packet. There will be an incoming axi stream for client to server communication and an outgoing axi stream for server to client communication
- The fpga side interface will be an ingoing axi stream to stream data through the core to the client. As well as the 32 registers (half readable and half writeable). The register written flag, the trigger signal, and the memory buffer that is still TBD


