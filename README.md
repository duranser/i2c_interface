# i2c_interface
* **I2C (Inter-Integrated Circuit)** is a hardware communication protocol that uses synchronous 8-bit-oriented serial communication bus between integrated circuits.
* **I2C** employs just two wires called **SCL (serial clock)** and **SDA (serial data)**. A common ground wire is also needed.
* **I2C** bus interconnects a master unit to a number of slave units. The **clock (SCL)** always generated by the master and it is unidirectional. Whereas the **data (SDA)** wire is bidirectional.
* **I2C** shares the same bus with typically 128 (7-bit address) or up to 1024 (10-bit address).
* **I2C** has different standardized speed modes, called standard (100 kbps), fast (400 kbps), fast-plus (1 Mbps), high-speed (3.4 Mbps), ultrafast (5 Mbps).

<img src="https://github.com/user-attachments/assets/0b36c649-a14c-4cd7-b9f8-ad6241b39975" width=60% height=60%>
Rp: pull-up resistors [1]

* **Start:** A start condition occurs at the start of a transmission and is initiated by the master. A high-to-low transition of **SDA** while **SCL** is high constitutes a start condition.
* **Address Frame:** The address frame contains a 7-bit or 10-bit sequence. The address frame is always the first frame after the start bit in a new message, and it is sent by the master.
* **Read/Write Bit:** The address frame also includes a single bit at the end that informs the slave whether the master wants to write data (R/W='0') to it or read data (R/W='1').
* **ACK/NACK Bit:** Each frame in a message is followed by an **acknowledge (ACK)** or **not-acknowledge (NACK)** bit. If an address frame or data frame was successfully received, an ACK bit is returned to the sender from the receiver.
* **Data Frame:** The data frame is always 8 bits long and sent with the most significant bit first. Each data frame is immediately followed by an **ACK/NACK** bit. Because SDA is a bidirectional line, during the **ACK/NACK** bit the transmitter must go to the high-impedance mode (‘Z’).
* **Stop:** After all the data frames have been sent, the master initiates a stop condition to halt the transmission. A low-to-high transition of **SDA** while **SCL** is high is a stop condition.


## Writing Procedure
* The master sends a start condition,
*	The master sends the slave address (typically 7-bit) plus a R/W=’0’ bit (for writing). 
*	The slave with the matched address respond with ACK bit (=0). 
*	The master sends data frame, 
*	The slave again responds with ACK = '0'. 
*	When the master is done transmitting, it sends the stop condition.

<img src="https://github.com/user-attachments/assets/f69c9720-a0d7-4d24-9594-5bfb0a4a099a" width=60% height=60%> [1]

## Reading Procedure
*	The master sends a start condition,
*	The master sends the slave address (typically 7-bit) plus a R/W=’1’ bit (for reading). 
*	The slave with the matched address respond with ACK bit (=0). 
*	The slave sends data frame, 
*	The master responds ACK bit to the slave to maintain data transfer(multiple bytes), or responds a NACK if the read request is already done.
*	When the master is done reading, it sends the stop condition.

<img src="https://github.com/user-attachments/assets/1fc680e1-b7b9-4d5a-ba94-b501334aed1e" width=80% height=80%> [1]


## References
[1] https://www.analog.com/en/resources/technical-articles/i2c-primer-what-is-i2c-part-1.html \
[2] V. A. Pedroni, Circuit Design with VHDL. TheMit Press, 2010.

