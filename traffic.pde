// =====================================================
//   CONSTANTS
// =====================================================

// CONSTANTS - GRAPHICS
static int constFrameRate = 30;
static int constResX = 720;
static int constResY = 720;

// CONSTANTS - SYSTEM
static int constNumPatterns = 11;
static int constFixedTimer = 3 * constFrameRate;
static float constAdvanceRate = 0.01;
static float constQueueSeperation = 0.025;

// CONSTANTS - MATH
static float MATH_E = 2.71828182845904523536028747135266249775724709369995;

// =====================================================
//   GLOBAL VARIABLES
// =====================================================

int priorityCalc = 2;
int switchDelay = 1;
int minimumEnable = 2;
float rate = 0.5;
Boolean priorityFixed = true;

// =====================================================
//   GLOBAL OBJECTS
// =====================================================

// OBJECTS - IMAGES
PImage imgCar, imgRoad, imgPatterns[];

// OBJECTS - ROUTES
Route r[];

// =====================================================
//   MATHS FUNCTIONS
// =====================================================

// Interp function
int interp(int start, int end, float p){
   return start + ceil((end - start) * p);
}

// =====================================================
//   CLASSES
// =====================================================

// CLASS - Point
class Point{
  int x, y;
  float p;
  
  Point(){
    x = 0;
    y = 0;
    p = 0;
  }
}

// CLASS - Car
class Car{
  int x, y, waitTime;
  float p;
  
  Car(float start){
    x = 0;
    y = 0;
    waitTime = 0;
    p = start;
  }
  
  int getPriority(){
    return parseInt( pow(waitTime, 2) );
  }
  
  void r90c(){
     int tx, ty;
     int newx, newy;
    
     tx = x - 360;
     ty = y - 360;
    
     newx = 360 + ty;
     newy = 360 - tx; 
     
     x = newx;
     y = newy;
  }
  
  void draw(){
    image(imgCar, x-8, y-8);
    //println(waitTime);
  }
}

// CLASS - Route
class Route{
  Point[] points;
  ArrayList<Car> carsQueue;
  ArrayList<Car> carsDone;
  boolean enabled;
  float pQueue;        // PROGRESS POINT AT WHICH CAR MUST QUEUE#
  float totalWaitTime;
  int totalDoneCars;
  int side;
  
  Route(int turn, int rot){
    enabled = false;
    side = rot;
    carsQueue = new ArrayList<Car>();
    carsDone = new ArrayList<Car>();
    
    // TURNS - 0 = left, 1 = straight, 2 = right
    // SIDES - 0 = left, 1 = bottom, 2 = right, 3 = top
    // Turn is computed, side affects draw rotation
    
    if (turn == 0){          // LEFT TURN
      points = new Point[4];
      points[0] = new Point(); points[0].x = 0; points[0].y = 270;
      points[1] = new Point(); points[1].x = 247; points[1].y = 270;
      points[2] = new Point(); points[2].x = 307; points[2].y = 270;
      points[3] = new Point(); points[3].x = 307; points[3].y = 0;
    } else if (turn == 1){   // STRAIGHT ON
      points = new Point[4];
      points[0] = new Point(); points[0].x = 0; points[0].y = 305;
      points[1] = new Point(); points[1].x = 247; points[1].y = 305;
      points[2] = new Point(); points[2].x = 500; points[2].y = 305;
      points[3] = new Point(); points[3].x = 720; points[3].y = 305;
    } else {                 // RIGHT TURN
      points = new Point[4];
      points[0] = new Point(); points[0].x = 0; points[0].y = 341;
      points[1] = new Point(); points[1].x = 247; points[1].y = 341;
      points[2] = new Point(); points[2].x = 414; points[2].y = 341;
      points[3] = new Point(); points[3].x = 414; points[3].y = 720;
    }
    
    for (int i = 0; i < points.length; i++){
      points[i].p = i * (1.0 / points.length);
    }
    
    pQueue = points[1].p;    // SET INITIAL Q POINT TO EDGE OF APPROACH
    totalWaitTime = 0;
    totalDoneCars = 0;
  }
  
  void setCarPos(Car c){
    
    int point = 1;
    for (int i = 1; i < points.length; i++){
       if (c.p < points[i].p){
          point = i;
          break;
       }
    }
   
    c.x = interp(points[point-1].x, points[point].x, (c.p-points[point-1].p)/(points[point].p - points[point-1].p));
    c.y = interp(points[point-1].y, points[point].y, (c.p-points[point-1].p)/(points[point].p - points[point-1].p));
    
    for (int i = 1; i < side+1; i++){
      c.r90c();
    }
  }
  
  void addCar(){
    if (pQueue > 0){
      carsQueue.add(new Car(0));
    } else {
    carsQueue.add(new Car(pQueue));
    }
  }

  int getPriority1(){
    // Returns total wait time
    int total = 0;
    int n = carsQueue.size();
    for(int i=0; i<n; i++){
      Car c = carsQueue.get(i);
      total += c.waitTime;
    }
    return total;
  }

  int getPriority2(){
    // Returns highest wait time
    int highest = 0;
    int n = carsQueue.size();
    for(int i=0; i<n; i++){
      Car c = carsQueue.get(i);

      if(c.waitTime > highest) {
        highest = c.waitTime;
      }
    }
    return highest;
  }

  int getPriority3(){
    // Wait time altered in some way before being used here
    // This function evaluates the product of (wait time squared)
    int total = 1;
    int n = carsQueue.size();
    for(int i=0; i<n; i++){
      Car c = carsQueue.get(i);
      total *= c.getPriority();
    }
    return total;
  }

  int getPriority4(){
    // Returns just the number of cars
    return carsQueue.size();
  }
  
  void tick(){
    // pQueue = points[1].p - ((carsQueue.size()-1) * constQueueSeperation);      // QUEUE POINT
    
    for (int i = 0; i < carsQueue.size(); i++){
      Car c = carsQueue.get(i);
      
      if (enabled){
        c.p += constAdvanceRate;
      } else {
        c.waitTime++;
        pQueue = points[1].p - (i*constQueueSeperation) - 0.02;
        if (c.p < pQueue){
          c.p += constAdvanceRate;
        }
      }
    }
    
    for (int i = 0; i < carsDone.size(); i++){
      Car c = carsDone.get(i);
      c.p += constAdvanceRate;
    }
    
    // OSCAR'S CAR ADDING CODE, please move if this is in the wrong place
    int expectedCars = int(get_cars( rate / constFrameRate )); 
    for(int i=0; i<expectedCars; i++) {
      addCar();
    }
    // END OF CODE

    checkCars();
  }
  
  void draw(){
    for (int i = 0; i < carsQueue.size(); i++){
      Car c = carsQueue.get(i);
      setCarPos(c);
      c.draw();
    }
    for (int i = 0 ; i < carsDone.size(); i++){
       Car c = carsDone.get(i);
       setCarPos(c);
       c.draw();
    }

  }
  
  void checkCars(){
     for (int i = 0; i < carsQueue.size(); i++){
       Car c = carsQueue.get(i);
       if (c.p >= points[1].p){
         carsDone.add(c);
         carsQueue.remove(i);
       }
     }
  
     for (int i = 0; i < carsDone.size(); i++){
       Car c = carsDone.get(i);
       if (c.p > 1){
          totalWaitTime += c.waitTime / constFrameRate;
          totalDoneCars++;
          carsDone.remove(i);
       }
     }
  }
}

class Pattern{
  Route[] routes;
  String[] routePrint;
  int priority;
  Boolean enabled;
  PImage img;

  Pattern(int patternid, Route[][] globalRoutes) {
    img = loadImage("p_" + nf(patternid, 2) + ".png");
    enabled = false;
    routes = new Route[4];
    // SIDES - 0 = left, 1 = bottom, 2 = right, 3 = top
    // From X to Y
    int[][] patterns = {{00,10,02,12},
                        {01,11,03,13},
                        {00,20,01,03},
                        {00,01,21,02},
                        {01,02,22,03},
                        {00,02,03,23},
                        {00,01,02,03},
                        {00,10,20,01},
                        {01,11,21,02},
                        {02,12,22,03},
                        {00,03,13,23}};
    // xy
    // x = Pattern index
    // y = Rotation / 90
    int[] pattern = patterns[ patternid ];

    routePrint = new String[4];

    for(int i=0; i<4; i++) {
      int[] splitTurn = decode(pattern[i]);
      int a = splitTurn[0];
      int b = splitTurn[1]; 
      routePrint[i] = str(a) + str(b);
      routes[i] = globalRoutes[a][b];
    }
  }

  int[] decode(int turn){
    int[] returnVal = new int[2];
    returnVal[1] = turn % 10;
    returnVal[0] = (turn - returnVal[1]) / 10;
    return returnVal;
  }

  int getPriority(){
    int total = 0;
    for(Route route : routes){
      switch(priorityCalc+1) {
        case 1:
          total += route.getPriority1();
          break;
        case 2:
          total += route.getPriority2();
          break;
        case 3:
          total += route.getPriority3();
          break;
        case 4:
          total += route.getPriority4();
          break;
      }
      
    }
    return total;
  }

  void printPattern() {
    for(int i=0; i<4; i++) {
      print(routePrint[i]);
      print(" ");
    }
    println("------");
  }

  void enable(){
    enabled = true;
    for(Route route : routes) {
      route.enabled = true;
    }
  }

  void disable(){
    enabled = false;
    for(Route route : routes) {
      route.enabled = false;
    }
  }

  void draw(){
    if(enabled) {
      image(img, 239, 239);
    }
  }
}

class Junction{
  Pattern[] patterns;
  Route[][] routes;
  Pattern enabledPattern;
  Boolean enabled;
  int timerDisabled;
  int timerFixed;
  int timerEnabled;
  int patternIndex;
  int switchPriority;

  Junction() {
    // Setup Routes
    routes = new Route[3][4];
    for(int i=0; i<3; i++) {
      for(int j=0; j<4; j++) {
        routes[i][j] = new Route(i, j);
      }
    }

    // Setup patterns
    patterns = new Pattern[11];
    for(int i=0; i<11; i++) {
      patterns[i] = new Pattern(i, routes);
    }

    enabled = false;
    timerDisabled = 2 * constFrameRate; // Let the junction fill up for 2 seconds
    timerEnabled = 0;
    patternIndex = int(random(patterns.length));
    enabledPattern = patterns[ patternIndex ];
    switchPriority = 0;
    timerFixed = constFixedTimer;
  }

  void printRoutes() {
    for(int i=0; i<3; i++) {
      for(int j=0; j<4; j++) {
        print(str(i) + str(j));
        if(routes[i][j].enabled) {
          println("  Y");
        } else {
          println("  N");
        }
      }
    }
  }

  void drawAverageWaitTimes() {
    float totalWaitTime = 0;
    int totalDoneCars = 0;
    for(int i=0; i<3; i++) {
      for(int j=0; j<4; j++) {
        // Draw stuff
        totalWaitTime += routes[i][j].totalWaitTime;
        totalDoneCars += routes[i][j].totalDoneCars;
        float averageWaitTime = routes[i][j].totalWaitTime / routes[i][j].totalDoneCars;
        text("Route[" + i + "][" + j + "] = " + str(averageWaitTime) ,480,10 + ((4*i)+j)*20);
        println("Route[" + i + "][" + j + "] = " + str(averageWaitTime));
      }
    }

    text("Average Car Wait Time: " + (totalWaitTime/totalDoneCars), 480, 600);

    println("Average Car Wait Time: " + (totalWaitTime/totalDoneCars));

  }

  void drawCurrentPriorityMethod() {
    text("Current Priority Method: " + (priorityCalc+1), 20, 20);
    text("Current Rate:            " + rate, 20, 40);
    String answer;
    if(priorityFixed){
      answer = "Yes";
    } else {
      answer = "No";
    }
    text("Fixed?                   " + answer, 20, 60);
    
    println("Priority Method: " + (priorityCalc+1));
    println("Rate:  " + rate);
    println("Fixed: " + answer);

  }

  void tick() {
    for( Pattern pattern : patterns) {
      pattern.draw();
    }

    for(int i=0; i<3; i++) {
      for(int j=0; j<4; j++) {
        routes[i][j].draw();
      }
    }
    
    if(enabled) {

      for(int i=0; i<3; i++) {
        for(int j=0; j<4; j++) {
          routes[i][j].tick();
        }
      }

      if(timerDisabled > 0) {
        timerDisabled--;
      } else if( priorityFixed ){
        enabledPattern.enable();
        enabledPattern.printPattern();
        printRoutes();
        if(timerFixed < 0) {
          // Cycle through the patterns with a fixed time
          patternIndex = (patternIndex+1) % patterns.length;
          enabledPattern.disable();
          enabledPattern = patterns[patternIndex];
          print("Switched\n");
          timerFixed = constFixedTimer;
          timerDisabled = switchDelay * constFrameRate;
        } else {
          timerFixed--;
        }
      } else {
        enabledPattern.enable();
        timerEnabled++;
        if(timerEnabled > minimumEnable*constFrameRate){
          // Compare the priorities of each patter
          int currentPriority;
          if (timerEnabled > 5 * constFrameRate) {
            currentPriority = 0;
          } else {
            currentPriority = enabledPattern.getPriority();
          }
          Pattern currentPattern = enabledPattern;
          for( Pattern pattern : patterns) {
            if( pattern.getPriority() > currentPriority) {
              currentPattern = pattern;
              currentPriority = currentPattern.getPriority();
            }
          }
          if(currentPattern != enabledPattern) {
            enabledPattern.disable();
            timerEnabled = 0;
            enabledPattern = currentPattern;
            switchPriority = enabledPattern.getPriority();
            println("Switch");
            timerDisabled = switchDelay*constFrameRate;
          }

        }
      }
    }
    println("-------------------------------");
    drawAverageWaitTimes();
    drawCurrentPriorityMethod();
  }
}

// =====================================================
//   FUNCTIONS
// =====================================================

// Get number of cars
int get_cars(float expected){
  float test = random(1);
  float total = 0;
  int k;
  for(k=0; test > total; k++) {
    total += ( pow(expected, parseFloat(k)) * pow(MATH_E, -expected) ) / fac(k);
  }
  return k-1;
}

// Fac for get_car
int fac(int n) {
  int total = 1;
  for(int i=2; i<=n; i++){
    total *= i;
  }
  return total;
}

Junction myJunction;

// Setup function
void setup(){
  size(constResX, constResY);
  frameRate(constFrameRate);
  
  textFont(createFont("NanumGothic", 14));
  
  imgCar = loadImage("car.png");
  imgRoad = loadImage("road.png");
  imgPatterns = new PImage[constNumPatterns];
  
  for (int i = 0; i < constNumPatterns; i++){
    imgPatterns[i] = loadImage("p_" + nf(i, 2) + ".png");
  }
  
  myJunction = new Junction();
  myJunction.enabled = true;
}

// Draw function
void draw(){
   image(imgRoad, 0, 0);
   myJunction.tick();
}

void keyPressed() {
  switch (key){
    case '+':
      rate += 0.1;
      break;
    case '-':
      if (rate > 0.1) rate -= 0.1;
      break;
    case ']':
      priorityCalc += 1;
      priorityCalc = priorityCalc % 4;
      break;
    case 'f':
      if (priorityFixed) {
        priorityFixed = false;
      } else {
        priorityFixed = true;
      }
  }
  resetJunction();
}

void resetJunction() {
  myJunction = new Junction();
  myJunction.enabled = true;
}
