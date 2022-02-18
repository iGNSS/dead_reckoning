# Dead reckoning system for CarriRo AD form factor

## Index

1. Introduction to dead reckoning
1. Mathematical representation of dead reckoning
1. Functional overview of the code
1. How to build and test the code
1. Room for improvements
1. Bibliography

## Introduction to dead reckoning

### What is dead reckoning ?

In navigation, dead reckoning is the process of calculating the current position of some moving object by using a previously determined position; and then incorporating a speed estimation, heading direction, and course over elapsed time. The corresponding term in biology, used to describe the processes by which animals update their estimates of position or heading, is path integration.[^1]

### Why would we need dead reckoning in our system ?

In our case, we consider the CarriRo AD as being the robot in which we will implement dead reckoning:

<p align="center">
  <img src="./Images/CarriRo.jpeg" />
  <br>
  <b>Fig.1 CarriRo Image</b>
</p>

As far as I know, the idea behind this robot is to have an autonomous moving cart that can handle heavy loads's transportation. A dead reckoning system would give this robot, the capability of knowing its current position in a 2D plane from an initially known position. That is an essential part when comming to implement navigation for autonomous robots.

In this use case, we have the following informations :
- The two rear wheels are driving wheels
- The two front wheels are swivel caster wheels
- We can get the odometry of the 4 wheels
- We can get the yaw rate of the whole robot

## Mathematical representation of dead reckoning

### Dead reckoning with odometry and yaw rate

In order to estimate our position, we have two kinds of available information. The 4 wheel odometry and the yaw rate. In this case, we will use odometry to calculate the robot shift, and the gyrometer to calculate the angle shift. We could use odometry alone to extract both of these parameters, but the gyrometer should be more precise when extracting the yaw angle.

### Coordinate system and robot initial position

We will use an orthonormal coordinate system. At initialization, *CarriRo AD* 0 coordinate is at the coordinate system origin. It is important to note that our *CarriRo AD* origin is the center between the two rear wheels (for simplicity purposes). Finally, carriro is facing the positive X axis.

<p align="center">
  <img src="./Images/coordinates.png" />
  <br>
  <b>Fig.2 Coordinates system</b>
</p>

<p align="center">
  <img src="./Images/CarriRo_mockup.png" />
  <br>
  <b>Fig.3 CarriRo representative illustration</b>
</p>

<p align="center">
  <img src="./Images/CarriRo_initial_position.png" />
  <br>
  <b>Fig.4 CarriRo inital position in the plane</b>
</p>

The angle &#952; is the angle between the direction of the robot and the x axis.

So at the beginning, our coordinates are the following ones :
- x = 0
- y = 0
- &#952; = 0

### From the physics to the math

In this section, we will cover how the odometry and yaw rate can be used to extract the absolute robot position.[^2]

First of all, we simplified the problem by taking into account only the two rear wheels because the front ones do not have any driving capacity.

The following image illustrates *CarriRo's* movement in the physical world.

<p align="center">
  <img src="./Images/real_robot_movement.png" />
  <br>
  <b>Fig.5 CarriRo real robot movement representation</b>
</p>

This trajectory can be decomposed in small curved segments as in the following image:

<p align="center">
  <img src="./Images/segmented_robot_movement.png" />
  <br>
  <b>Fig.6 CarriRo segmented robot movement representation</b>
</p>

If we focus on a single segment, we can extract the yaw angle and robot shift:

<p align="center">
  <img src="./Images/shift_extraction.png" />
  <br>
  <b>Fig.7 CarriRo segment data</b>
</p>

From the representation of our robot, we can extract the following set equations:

- d<sub>R</sub> = (R + 2*R<sub>W</sub>)*&Delta;&theta;
- d<sub>L</sub> = R*&Delta;&theta;
- d = (R + R<sub>W</sub>)*&Delta;&theta;

With some basic math, we get to the following equation:
- d = (d<sub>R</sub> + d<sub>L</sub>)/2

### From relative movement to absolute coordinates

In the last section, we just extracted the robot movement regarding the last segment. But now, we need to use this in order to know where our robot is in the absolute coordinates system. In order to do that, we need to convert the yaw angle and the position shift to an x and y coordinates and to an absolute angle between the x axis and the robot direction.

To simplify things, we imagine that the robot does a slight rotation on the spot before going straight. This allows us to use the d distance as if it was straight forward:

<p align="center">
  <img src="./Images/robot_shift_absolute_coordinates.png" />
  <br>
  <b>Fig.8 Robot shift to absolute coordinates</b>
</p>

**Legend :**
- y: y axis
- x: x axis
- (x<sub>t-1</sub>, y<sub>t-1</sub>): last scan coordinates
- (x<sub>t</sub>, y<sub>t</sub>): new scan coordinates
- &Delta;&theta;: yaw angle between last direction and new direction
- &Delta;x: variation on x axis
- &Delta;y: variation on y axis
- &theta;<sub>t</sub>: absolute angle between x axis and the robot direction
- &theta;<sub>t-1</sub>: absolute angle between x axis and the robot direction in the last scan

To update our absolute angle, we take the yaw angle and add it to the last angle:
- &theta;<sub>t</sub> = &Delta;&theta; + &theta;<sub>t-1</sub>

With some trigonometry, we can extract &Delta;x and &Delta;y:
- &Delta;x = d cos(&theta;<sub>t</sub>)
- &Delta;y = d sin(&theta;<sub>t</sub>)

And our new absolute coordinates are:
- x<sub>t</sub> = x<sub>t-1</sub> + &Delta;x
- y<sub>t</sub> = y<sub>t-1</sub> + &Delta;y
- &theta;<sub>t</sub>

## Functional overview of the code

### Mockup of the gyrometer and odometry acquisition

In order to simulate the odometry and the yaw rate acquisition functions, I made a mockup library that had two functions: one for odometry and one for the gyrometer.
```c++
int gyrometerAcq(float &yawRate, uint32_t &timestamp);
int odometryAcq(std::array<float, 4> &odometry, uint32_t &timestamp);
```

*Note : For simplicity, we supposed that this library returns the odometry values between the last acq and the new one.*

The output values are actually given by reference and the returned value corresponds to the success or failure of the function. Regarding the timestamp, it is referenced to 0 at boot.

### How is built the library and how to use it

The library consists of one class `robotPosition` that contains three public methods, eight private ones and one public attribute. To use this library, you first need to create an instance of the class. Then three functions can be used, one is for yaw angle update loop, the second one is for position update loop and the last one is to launch a multi threaded loop where you can choose the refresh rate of the yaw angle and odometry. The attribute is the global position of the robot in (x,y,&theta;) coordinates:
```c++
class robotPosition{
  public:
    std::array<float, COORDS_SIZE> coords = {0, 0, 0};

    robotPosition(void);
    ~robotPosition(void);

    void updateCoordsThreads(int gyroFreqHz, int odometryFreqHz);

    void updateAngleLoop(int gyroFreqHz);

    void updateXYLoop(int odometryFreqHz);
    ...
```

## Build and tests

### Requirements

Before building and testing your code, please make sure to have the following installs:
- g++
- gdb
- CppUTest[^3]

And do the following configurations:
- Replace the `CPPUTEST_HOME` value in the make file with your absolute path to it

### Build and test commands

We have made three kinds of builds : a test build, an executable build and a library build.
In order to build them, you just need to go to `Dead_reckoning_system` and type:
- `make tests` for the unitary tests
- `make dead_reckoning` for the executable
- `make library` for the static library

*Note: in the makefile there is a debug flag used to print some debug information. You can remove it for release.*

## Room for improvements

### Thread safety

For the moment, the treads in
```c++
void updateCoordsThreads(int gyroFreqHz, int odometryFreqHz);
```
are completely unsafe. Actually they manipulate the same variable (`std::array<float, COORDS_SIZE> coords;`) and this could be very conflicting. In order to avoid this, we should add a mutex to ensure the correct lecture and update of the coords variable.

### Take speed in account

Currently our code gets the yawRate and odometry with different rates. But after getting these values, we only update the variable that is directly associated with it (if we get odometry, we update x and y but not yaw angle and vice versa). But if we take into account the speeds of x, y and yaw angle we could predict the current position of all the variables.

**Concretely:**
- **When we get the odometry, we update the yaw angle with the last yaw rate.**
- **When we get the yaw rate, we update the x and y coordinates with their speed.**

This could give our application better precision.

### Global positioning system and Kalman filter

A big problem of dead reckoning is that it tends to shift over traveled distance. So the predictions that might be accurate after 10 meters of traveling, could be very wrong after 100m. So in order to maintain the good positioning of the robot it is useful to integrate a global position system. For outdoors applications GPS are really good, but as CarriRo is mostly used indoors, a local system (apriltags, signal triangulation, ...) should be used.

And in order to integrate a dead reckoning system and a global positioning input, a kalman filter could be used to filter out acquisition errors.

## Bibliography

[^1]: Wikipedia: https://en.wikipedia.org/wiki/Dead_reckoning
[^2]: A good explanation: https://www.youtube.com/watch?v=LrsTBWf6Wsc&t=1554s
[^3]: Can be downloaded here: http://cpputest.github.io/
