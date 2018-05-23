// You need the controlP5 library from http://www.sojamo.de/libraries/controlP5/
import controlP5.*;

//You need the Toxic Libs library: http://hg.postspectacular.com/toxiclibs/downloads
import toxi.geom.*;
import toxi.geom.mesh2d.*;
import toxi.util.datatypes.*;
import toxi.processing.*;

import javax.swing.UIManager;
import javax.swing.JFileChooser;

 int mainwidth;
int mainheight;
// helper class for rendering
ToxiclibsSupport gfx;

// Feel free to play with these three default settings
float cutoff = 0.1;
float minDotSize = 0.2;
float dotSizeFactor = 5;

// Max value is normally 10000. Press 'x' key to allow 50000 stipples. (SLOW)
int maxParticles;

//Scale each cell to fit in a cellBuffer-sized square window for computing the centroid.
int cellBuffer = 100;

// Display window and GUI area sizes:
int textColumnStart;
float maxDotSize;
boolean saveNow;
String[] fileOutput;
boolean fillingCircles;

String statusDisplay = "Initializing, please wait. :)";

int generation;
int particleRouteLength;
int routeStep;
String txtfilename, ext;

int vorPointsAdded;
boolean voronoiCalculated;

int cellsTotal, cellsCalculated, cellsCalculatedLast;

int[] particleRoute;
Vec2D[] particles;

ControlP5 cp5;
Voronoi voronoi;
Polygon2D regionList[];
PolygonClipper2D clip;
  String filename = "";

PImage imgOriginal, imgCyan, imgMagenta, imgYellow, imgBlack, imgblur;
int topegeneration;
void setup() {
    fillingCircles = true;

  //size(1366, 710);

    gfx = new ToxiclibsSupport(this);

  
  if (args != null) {
      filename = args[0];
      topegeneration = int(args[2]);
      maxParticles = int(args[1]);
  } else {
    //selectInput("Select a file to process:", "fileSelected");
    filename = "paleta.png";
    //filename = "color_wheel.png";
    String[] p = splitTokens(filename, ".");
    for (int i=0; i< p.length; i++) {
      println(i,p[i]);
    }
    
    txtfilename = p[0];
    ext = p[1];
    
    
    topegeneration = 1;
    maxParticles = 2500;
  }

    
    println("Cargando archivo:" + filename);

    imgOriginal = loadImage(filename);
    
    mainwidth = imgOriginal.width;
    mainheight = imgOriginal.height;

    imgCyan     = createImage(imgOriginal.width, imgOriginal.height, RGB);
    imgMagenta  = createImage(imgOriginal.width, imgOriginal.height, RGB);
    imgYellow   = createImage(imgOriginal.width, imgOriginal.height, RGB);
    imgBlack    = createImage(imgOriginal.width, imgOriginal.height, RGB);

    float c,m,y,r,g,b,k;

    imgOriginal.loadPixels();
    imgCyan.loadPixels();
    imgMagenta.loadPixels();
    imgYellow.loadPixels();
    imgBlack.loadPixels();
 
    for (int i = 0; i < imgOriginal.pixels.length; i++) {
      
      r = ((imgOriginal.pixels[i] >> 16 &0xFF));
      g = ((imgOriginal.pixels[i] >> 8 &0xFF));
      b = ((imgOriginal.pixels[i] &0xFF));
      //r = red(img.pixels[i]);
      //g = green(img.pixels[i]);
      //b = blue(img.pixels[i]);
      c = 1 - r / 255;
      m = 1 - g / 255;
      y = 1 - b / 255;
    
    if (c + m + y != 0) {
        k = min(c,m,y);
    } else {
        k = 1;
    }
     
    if (k == 1) {
        c = 0;
        m = 0;
        y = 0;
        k = 0;
    } else {
        c = (c - k) / (1 - k);
        m = (m - k) / (1 - k);
        y = (y - k) / (1 - k);
    }

    imgCyan.pixels[i] = int((1-c) * 255);
    imgMagenta.pixels[i] = int((1-m) * 255);
    imgYellow.pixels[i] = int((1-y) * 255);
    imgBlack.pixels[i] = int((1-k) * 255);
    }
    
    
    imgCyan.loadPixels();
    imgCyan.filter(INVERT);
    imgCyan.save(txtfilename + "_cyan." + ext);

    imgMagenta.loadPixels();
    imgMagenta.filter(INVERT);
    imgMagenta.save(txtfilename + "_magenta." + ext);
    
    imgYellow.loadPixels();
    imgYellow.filter(INVERT);
    imgYellow.save(txtfilename + "_yellow." + ext);
    
    imgBlack.loadPixels();
    imgBlack.filter(INVERT);
    imgBlack.save(txtfilename + "_black." + ext);

}


void draw() {
  
/*
  println("Antes de procesar()");  
  imgCyan.loadPixels();
  imgblur = createImage(imgOriginal.width, imgOriginal.height, RGB);
  imgblur = imgCyan;
  imgblur.loadPixels();
  noStroke();
  procesar("cyan.svg");
  imgMagenta.loadPixels();
  imgblur = createImage(imgOriginal.width, imgOriginal.height, RGB);
  imgblur = imgMagenta;
  imgblur.loadPixels();
  noStroke();
  procesar("magenta.svg");
  imgYellow.loadPixels();
  imgblur = createImage(imgOriginal.width, imgOriginal.height, RGB);
  imgblur = imgYellow;
  imgblur.loadPixels();
  noStroke();
  procesar("yellow.svg");
  imgBlack.loadPixels();
  imgblur = createImage(imgOriginal.width, imgOriginal.height, RGB);
  imgblur = imgBlack;
  imgblur.loadPixels();
  noStroke();
  procesar("black.svg");

  println("Despues de procesar()");   //<>//
  */
  println("SALIDA");
  exit();
}
