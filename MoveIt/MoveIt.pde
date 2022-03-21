// Difference between 2 consecutive frames
import processing.video.*;
import java.util.ArrayList;
import java.util.Iterator;
import gifAnimation.*;
final int CNT = 2;
// Capture size
final int CAPW = 640;
final int CAPH = 480;
// Minimum bounding box area
final float MINAREA = 0.0001;
boolean targetDestroyed = true;
//target rectangle values
int x=0;
int y = 0;
int rwidth = 20;
int rheight = 20;
//gaming values
boolean isFirstRound = true;
boolean gameStarted = false;
int highScore = 0;
int score = -1;
int gameCounter = 0;

Capture cap;
// Previous and current frames in Mat format
Mat [] frames;
int prev, curr;
CVImage img;
// Display size
int dispW, dispH;

void setup() {
  size(800, 600);
  System.loadLibrary(Core.NATIVE_LIBRARY_NAME);
  cap = new Capture(this, CAPW, CAPH, "pipeline:autovideosrc");
  cap.start();
  img = new CVImage(width, height);
  frames = new Mat[CNT];
  for (int i=0; i<CNT; i++) {
    frames[i] = new Mat(img.height, img.width,
      CvType.CV_8UC1, Scalar.all(0));
  }
  prev = 0;
  curr = 1;
}

void draw() {
  if (!cap.available())
    return;
  background(0);
  cap.read();
  PImage tmp0 = createImage(width, height, ARGB);
  tmp0.copy(cap, 0, 0, cap.width, cap.height,
    0, 0, tmp0.width, tmp0.height);
  // Display current frame.
  scale(-1, 1);
  image(tmp0, -width, 0);
  scale(-1, 1);
  if (gameStarted) {
    //begin game
    gameCounter++;
    if (gameCounter % 600 == 0) {
      //30 seconds and game are over
      gameCounter = 0;
      gameStarted = false;
      isFirstRound = false;
    } else {
      //game is going on
      img.copyTo(tmp0);
      frames[curr] = img.getGrey();
      CVImage out = new CVImage(width, height);
      out.copyTo(frames[prev]);
      Mat tmp1 = new Mat();
      Mat tmp2 = new Mat();
      // Difference between previous and current frames
      Core.absdiff(frames[prev], frames[curr], tmp1);
      Imgproc.threshold(tmp1, tmp2, 40, 255, Imgproc.THRESH_BINARY);
      out.copyTo(tmp2);
      // Obtain contours of the difference binary image
      ArrayList<MatOfPoint> contours = new ArrayList<MatOfPoint>();
      Mat hierarchy = new Mat();
      Imgproc.findContours(tmp2, contours, hierarchy,
        Imgproc.RETR_LIST, Imgproc.CHAIN_APPROX_SIMPLE);
      Iterator<MatOfPoint> it = contours.iterator();
      while (it.hasNext()) {
        MatOfPoint cont = it.next();
        // Draw each bounding box
        Rect rct = Imgproc.boundingRect(cont);
        float area = (float)(rct.width * rct.height);
        if (area < MINAREA)
          continue;
        /*rect(-(float)rct.x, (float)rct.y,
         (float)rct.width, (float)rct.height);*/
         //check if frame difference overlaps rectangle
        if (isOverlapping(rct, x, y, rwidth, rheight)) {
          targetDestroyed = true;
        }
      }
      int temp = prev;
      prev = curr;
      curr = temp;
      hierarchy.release();
      tmp1.release();
      tmp2.release();

      if (targetDestroyed) {
        //User has moved through
        fill(255);
        if (gameCounter %20 == 0) {
          score+=1;
          //new rect
          x = int(random(20, width));
          y = int(random(height-20));
          targetDestroyed = false;
        }
      }
      //draw target
      rect(width-x, y, rwidth, rheight);
      text("Score: "+score, 650, 550);
    }
  } else {
    if (!isFirstRound) {
      //finish Screen
      if (score > highScore) {
        textSize(65);
        text("Congratulations!", 200, 200);
        textSize(50);
        text("There is Now New High Score!", 100, 270);
        text("The High Score: "+score+" Points", 180, 350);
      } else {
        textSize(50);
        text("Your Score: "+score, 100, 270);
        text("High Score: "+highScore, 400, 270);
      }
    }
    textSize(30);
    text("Move Through the White Rectangles Quickly to Gain Points", 40, 500);
    if (isFirstRound) {
      text("Press Enter to Start", 300, 550);
    } else {
      text("Press Enter to Play Again", 260, 550);
    }
  }
}

public boolean isOverlapping(Rect first, int x, int y, int rwidth, int rheight) {
  //check if rectangle first and target are overlapping
  if (first.y > y+rheight
    || first.y+first.height < y) {
    return false;
  }
  if (first.x+first.width < x
    || first.x > x+rwidth) {
    return false;
  }
  return true;
}

void keyPressed() {
  //initialize new round
  if (keyCode == ENTER) {
    gameStarted = true;
    if (score > highScore) {
      highScore = score;
    }
    score = 0;
  }
}
