
/*
 * setup pins
 */
const int solarPin = 5;
const int tempPin  = 2;
const int btnPin = 7;
const int ledPin = 9;

char msgstr[100];

int lastBtnState = LOW;
long lastDebounceTime = 0;
long debounceDelay = 50;

void setup(){
  Serial.begin(9600);
  
  // setup Pin mode
  pinMode(btnPin, INPUT);
  pinMode(ledPin, OUTPUT);

  delay(1000);
  
  Serial.println("Startup temp sensor.");
}

void loop(){
  int btnState = digitalRead(btnPin);
  int solarVal = analogRead(solarPin);
  int tempVal  = analogRead(tempPin);
  
  if ( lastBtnState == LOW && btnState == HIGH ) {
    int now = millis();
    if (( now - lastDebounceTime ) > debounceDelay ) {
      int temperature = map(tempVal, 0, 327, 0, 160) - 60;
      float solarpower  = (solarVal * 4.88) / 1024;
      int solarpower1 = (solarpower - (int)solarpower) * 100;
      
      sprintf(msgstr,"Temperature: %d, Solar Power: %0d.%d", 
        temperature,(int)solarpower,solarpower1);
      Serial.println(msgstr);
    }
    lastDebounceTime = now;
  }
  lastBtnState = btnState;
  
  analogWrite(ledPin, map(solarVal, 0, 1024, 0, 255));
}

