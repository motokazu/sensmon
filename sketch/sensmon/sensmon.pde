/*
  sensmon arduino sketch.
 
 created 14 Nov 2010.
 by Motokazu Nishimura.
 */

#include <SPI.h>

#include <Ethernet.h>
#include <string.h>
#include <Time.h>
#include <UdpBytewise.h>  // UDP library from: bjoern@cs.stanford.edu 12/30/2008 

#if  UDP_TX_PACKET_MAX_SIZE <64 ||  UDP_RX_PACKET_MAX_SIZE < 64
#error : UDP packet size to small - modify UdpBytewise.h to set buffers to 64 bytes
#endif

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 0, 50 };
byte gw[] = { 192, 168, 0, 1 };
byte subnet[] = { 255, 255, 255, 0 };
byte server[] = { 192, 168, 0, 80 }; // sheevabian

byte SNTP_server_IP[] = { 130, 69, 251, 23 }; // Tokyo-univ NTP
time_t prevDisplay = 0; // when the digital clock was displayed
const  long timeZoneOffset = -32400; // set JST. set this to the offset in seconds to your local time;

void setup()
{
  Ethernet.begin(mac, ip, gw, subnet);
  Serial.begin(9600);
  
  delay(1000);
  
  Serial.println("Startup Sensmon. let's relax arduino.");
  Serial.println("waiting for sync NTP");
  setSyncProvider(getNtpTime);
  while(timeStatus()== timeNotSet)  
     ; // wait until the time is set by the sync provider
}

boolean post()
{
  char json[256];
  char q = '"';
  char clength[30];
  char timestr[20];
  
  int sensorValue = analogRead(0);
  // reverse sens data
  sensorValue = 1024 - sensorValue;
  
  sprintf(timestr,"%04d/%02d/%02d %02d:%02d:%02d",year(),month(),day(),hour(),minute(),second());
  Serial.println(timestr);
  
  sprintf(json,"{%cstime%c:%c%s%c, %cvalue%c:%d}",q,q,q,timestr,q,q,q,sensorValue);
  Serial.println(json);
  
  Client client(server, 5984); // connect couchdb
  Serial.println("connecting couchdb...");
  
  if(client.connect()){
    Serial.println("connected");
    client.println("POST /sensmon HTTP/1.1");
    client.println("Host: sheevabian");
    client.println("Authorization: Basic bW90b2thenU6YXNkZmFzZGY=");
    client.println("Content-Type: application/json");
    sprintf(clength,"Content-Length: %d",strlen(json));
    client.println(clength);
    client.println("Connection: Close");
    client.println();
    client.print(json);
    Serial.println("POST OK");
  } else {
    Serial.println("connection failed");
    return false;
  }              
  client.stop();
  return true;
}

void loop()
{
  post();
  delay(60000);
}

/*-------- NTP code ----------*/

unsigned long getNtpTime()
{
  sendNTPpacket(SNTP_server_IP);
  delay(1000);
  if ( UdpBytewise.available() ) {
    for(int i=0; i < 40; i++)
       UdpBytewise.read(); // ignore every field except the time
    const unsigned long seventy_years = 2208988800UL + timeZoneOffset;        
    return getUlong() -  seventy_years;      
  }
  return 0; // return 0 if unable to get the time
}

unsigned long sendNTPpacket(byte *address)
{
  UdpBytewise.begin(123);
  UdpBytewise.beginPacket(address, 123);
  UdpBytewise.write(B11100011);   // LI, Version, Mode
  UdpBytewise.write(0);    // Stratum
  UdpBytewise.write(6);  // Polling Interval
  UdpBytewise.write(0xEC); // Peer Clock Precision
  write_n(0, 8);    // Root Delay & Root Dispersion
  UdpBytewise.write(49); 
  UdpBytewise.write(0x4E);
  UdpBytewise.write(49);
  UdpBytewise.write(52);
  write_n(0, 32); //Reference and time stamps  
  UdpBytewise.endPacket();   
}

unsigned long getUlong()
{
    unsigned long ulong = (unsigned long)UdpBytewise.read() << 24;
    ulong |= (unsigned long)UdpBytewise.read() << 16;
    ulong |= (unsigned long)UdpBytewise.read() << 8;
    ulong |= (unsigned long)UdpBytewise.read();
    return ulong;
}

void write_n(int what, int how_many)
{
  for( int i = 0; i < how_many; i++ )
    UdpBytewise.write(what);
}
