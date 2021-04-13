#include <EEPROMex.h>

const int camPin = 5;//6
const int diaPin = 8;
const int startButtonPin = 4;
const int pauseButtonPin = 3;
//const int dialedPin = 13; 

int stataddress = 0;
int camDelayPoti = A0;
int diaDelayPoti = A1;

int diaMagMax = 50;
long statCount;
long delayAfterCamTriggerStd = 300; 
long delayAfterDiaTriggerStd = 1200; 
long camHighDur=80;//35
long diaHighDur=120;//150


int paused = false;
int pausePressed = false;
int startPressed = false;
int buttonState = LOW;
boolean ppressed = false;
boolean spressed = false;

boolean cycling = false;
long delayAfterCamTrigger = 0;
long delayAfterDiaTrigger = 0;
int diaCount = 0;

boolean diaTriggered = false;
boolean camTriggered = false;
unsigned long TIMER = 0;

void setup() {
  ////EEPROM.writeLong(stataddress, 0L); //only once to reset
  statCount = EEPROM.readLong(stataddress);
  ////Serial.begin(9600);
  ////Serial.print("TOTAL CYCLES TILL NOW: ");
  ////Serial.println(statCount);

  pinMode(camPin, OUTPUT);
  pinMode(diaPin, OUTPUT);
  pinMode(pauseButtonPin, INPUT);
  
  //make sure EOS is ready
  digitalWrite(camPin, HIGH);
  digitalWrite(camPin, LOW); 
  
  delay(1000);
  TIMER = millis();
}

void loop() {
  
  if(cycling && !paused && (diaCount < diaMagMax)) {
    delayAfterCamTrigger = delayAfterCamTriggerStd + map(analogRead(camDelayPoti), 0, 1023, -delayAfterCamTriggerStd, delayAfterCamTriggerStd);
    delayAfterDiaTrigger = delayAfterDiaTriggerStd + map(analogRead(diaDelayPoti), 0, 1023, -delayAfterDiaTriggerStd, delayAfterDiaTriggerStd);
    
    
    if(!diaTriggered && (TIMER + delayAfterCamTrigger) < millis()) {
      diaTriggered = true;
  
      digitalWrite(diaPin, HIGH);
      delay(diaHighDur);
      digitalWrite(diaPin, LOW);
     }
     
     
    if(!camTriggered && diaTriggered && (TIMER + delayAfterCamTrigger +delayAfterDiaTrigger) < millis()) {
      camTriggered = true;
      
      digitalWrite(camPin, HIGH);
      delay(camHighDur);
      digitalWrite(camPin, LOW);
      
      diaTriggered = false;
      camTriggered = false;
      TIMER = millis();
      diaCount++;
      statCount = statCount+1L;
      
      if(statCount != 0L && statCount % 40L == 0L) {
        EEPROM.updateLong(stataddress, statCount);
        //Serial.println(EEPROM.readLong(stataddress));
      } 
      
      if(pausePressed && !paused) {
        paused = true;
        pausePressed = false;
      }
      if(startPressed) {
        startPressed = false;
        if(cycling) {
          cycling = false;
          diaCount = 0;
          TIMER = millis();
        }
      }
    } 
  }
  else {
    if (pausePressed && paused) {
         paused = false;
         pausePressed = false;
         TIMER = millis();
    } 
    
    if(startPressed) {
      startPressed = false;
      if(cycling) {
        cycling = false;
        diaCount = 0;
        TIMER = millis();
      }
    }
    
    if(diaCount == diaMagMax) {
     cycling = false;
     diaCount = 0; 
     delay(750);
     digitalWrite(diaPin, HIGH);  
     delay(diaHighDur);
     digitalWrite(diaPin, LOW);
    }
  }
    
    
    
  buttonState = digitalRead(startButtonPin);
  if (buttonState == HIGH) {
    spressed = true;
  }
  if(spressed && buttonState == LOW) { // released
      spressed = false;
      if(!cycling) {   
        setup();   
        cycling = true;
      } else {
        startPressed = true; 
      }
  }

  buttonState = digitalRead(pauseButtonPin);
  if (buttonState == HIGH) {
    ppressed = true;
  }
  if(ppressed && buttonState == LOW) { // released
    ppressed = false;
    if(!cycling) {
      digitalWrite(camPin, HIGH);
      delay(camHighDur);
      digitalWrite(camPin, LOW);
    }
  }
  
  
  //tmp = analogRead(camDelayPoti);
 //Serial.println(delayAfterCamTrigger);
  
  //tmp = analogRead(diaDelayPoti);
 //Serial.println(delayAfterDiaTrigger);
 
  //delay(1);
}
