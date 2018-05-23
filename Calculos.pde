String makeSpiral ( float xOrigin, float yOrigin, float turns, float radius)
{
  float resolution = 20.0;

  float AngleStep = TAU / resolution;
  float ScaledRadiusPerTurn = radius / (TAU * turns);

  String spiralSVG = "<path d=\"M " + xOrigin + "," + yOrigin + " "; // Mark center point of spiral

  float x, y;
  float angle = 0;

  int stopPoint = ceil (resolution * turns);
  int startPoint = floor(resolution / 4);  // Skip the first quarter turn in the spiral, since we have a center point already.

  if (turns > 1.0) { // For small enough circles, skip the fill, and just draw the circle.
    for (int i = startPoint; i <= stopPoint; i = i+1) {
      angle = i * AngleStep;
      x = xOrigin + ScaledRadiusPerTurn * angle * cos(angle);
      y = yOrigin + ScaledRadiusPerTurn * angle * sin(angle);
      spiralSVG += x + "," + y + " ";
    }
  }

  // Last turn is a circle:
  //float CircleRad = ScaledRadiusPerTurn * angle;

  for (int i = 0; i <= resolution; i = i+1) {
    angle += AngleStep;
    x = xOrigin + radius * cos(angle);
    y = yOrigin + radius * sin(angle);

    spiralSVG += x + "," + y + " ";
  }

  spiralSVG += "\" />" ;
  return spiralSVG;
}


void optimizePlotPath() {
  int temp;
  // Calculate and show "optimized" plotting path, beneath points.

  //println("Optimizing plotting path"+routeStep);
  
  if (routeStep % 100 == 0) {
    println("Optimizing plotting path :: RouteStep:" + routeStep);
    //println("fps = " + frameRate );
  }
  

  Vec2D p1;

  if (routeStep == 0) {
    float cutoffScaled = 1 - cutoff;
    // Begin process of optimizing plotting route, by flagging particles that will be shown.

    particleRouteLength = 0;

    boolean particleRouteTemp[] = new boolean[maxParticles];

    for (int i = 0; i < maxParticles; ++i) {
      particleRouteTemp[i] = false;

      int px = (int) particles[i].x;
      int py = (int) particles[i].y;

      if ((px >= imgblur.width) || (py >= imgblur.height) || (px < 0) || (py < 0)) {
        continue;
      }

      float v = (brightness(imgblur.pixels[py * imgblur.width + px])) / 255;

      if (v < cutoffScaled) {
        particleRouteTemp[i] = true;
        particleRouteLength++;
      }
    }

    particleRoute = new int[particleRouteLength];
    int tempCounter = 0;
    for (int i = 0; i < maxParticles; ++i) {
      if (particleRouteTemp[i]) {
        particleRoute[tempCounter] = i;
        tempCounter++;
      }
    }
    // These are the ONLY points to be drawn in the tour.
  }

  if (routeStep < (particleRouteLength - 2)) {
    // Nearest neighbor ("Simple, Greedy") algorithm path optimization:

    int StopPoint = routeStep + 1000; // 1000 steps per frame displayed; you can edit this number!

    if (StopPoint > (particleRouteLength - 1)) {
      StopPoint = particleRouteLength - 1;
    }

    for (int i = routeStep; i < StopPoint; ++i) {
      p1 = particles[particleRoute[routeStep]];
      int ClosestParticle = 0;
      float  distMin = Float.MAX_VALUE;

      for (int j = routeStep + 1; j < (particleRouteLength - 1); ++j) {
        Vec2D p2 = particles[particleRoute[j]];

        float  dx = p1.x - p2.x;
        float  dy = p1.y - p2.y;
        float  distance = (float) (dx*dx+dy*dy);  // Only looking for closest; do not need sqrt factor!

        if (distance < distMin) {
          ClosestParticle = j;
          distMin = distance;
        }
      }

      temp = particleRoute[routeStep + 1];
      // p1 = particles[particleRoute[routeStep + 1]];
      particleRoute[routeStep + 1] = particleRoute[ClosestParticle];
      particleRoute[ClosestParticle] = temp;

      if (routeStep < (particleRouteLength - 1)) {
        routeStep++;
      } else {
        println("Now optimizing plot path" );
      }
    }
  } else {     // Initial routing is complete
    // 2-opt heuristic optimization:
    // Identify a pair of edges that would become shorter by reversing part of the tour.

    for (int i = 0; i < 1000; ++i) {   // 1000 tests per frame; you can edit this number.
      int indexA = floor(random(particleRouteLength - 1));
      int indexB = floor(random(particleRouteLength - 1));

      if (Math.abs(indexA  - indexB) < 2) {
        continue;
      }

      if (indexB < indexA) { // swap A, B.
        temp = indexB;
        indexB = indexA;
        indexA = temp;
      }

      Vec2D a0 = particles[particleRoute[indexA]];
      Vec2D a1 = particles[particleRoute[indexA + 1]];
      Vec2D b0 = particles[particleRoute[indexB]];
      Vec2D b1 = particles[particleRoute[indexB + 1]];

      // Original distance:
      float  dx = a0.x - a1.x;
      float  dy = a0.y - a1.y;
      float  distance = (float)(dx*dx+dy*dy);  // Only a comparison; do not need sqrt factor!
      dx = b0.x - b1.x;
      dy = b0.y - b1.y;
      distance += (float)(dx*dx+dy*dy);  //  Only a comparison; do not need sqrt factor!

      // Possible shorter distance?
      dx = a0.x - b0.x;
      dy = a0.y - b0.y;
      float distance2 = (float)(dx*dx+dy*dy);  //  Only a comparison; do not need sqrt factor! 
      dx = a1.x - b1.x;
      dy = a1.y - b1.y;
      distance2 += (float)(dx*dx+dy*dy);  // Only a comparison; do not need sqrt factor! 

      if (distance2 < distance) {
        // Reverse tour between a1 and b0.

        int indexhigh = indexB;
        int indexlow = indexA + 1;

        println("Shorten!" + frameRate );

        while (indexhigh > indexlow) {
          temp = particleRoute[indexlow];
          particleRoute[indexlow] = particleRoute[indexhigh];
          particleRoute[indexhigh] = temp;

          indexhigh--;
          indexlow++;
        }
      }
    }
  }

}

void doPhysics() {   // Iterative relaxation via weighted Lloyd's algorithm.
  int temp;

  if (!voronoiCalculated) {
    // Part I: Calculate voronoi cell diagram of the points.

    statusDisplay = "Calculating Voronoi diagram ";

    if (vorPointsAdded == 0) {
      voronoi = new Voronoi();  // Erase mesh
    }

    temp = vorPointsAdded + 500;   // This line: VoronoiPointsPerPass  (Feel free to edit this number.)
    if (temp > maxParticles) {
      temp = maxParticles;
    }

    for (int i = vorPointsAdded; i < temp; i++) {
      // Optional, for diagnostics:::
      //println("particles[i].x, particles[i].y " + particles[i].x + ", " + particles[i].y );

      voronoi.addPoint(new Vec2D(particles[i].x, particles[i].y ));
      vorPointsAdded++;
    }

    if (vorPointsAdded >= maxParticles) {
      cellsTotal = voronoi.getRegions().size();
      vorPointsAdded = 0;
      cellsCalculated = 0;
      cellsCalculatedLast = 0;

      regionList = new Polygon2D[cellsTotal];

      int i = 0;
      for (Polygon2D poly : voronoi.getRegions()) {
        regionList[i++] = poly;  // Build array of polygons
      }
      voronoiCalculated = true;
    }
  } else {    // Part II: Calculate weighted centroids of cells.
    statusDisplay = "Calculating weighted centroids";

    temp = cellsCalculated + 500;   // This line: CentroidsPerPass  (Feel free to edit this number.)
    // Higher values give slightly faster computation, but a less responsive GUI.
    // Default value: 500

    if (temp > cellsTotal) {
      temp = cellsTotal;
    }

    for (int i=cellsCalculated; i< temp; i++) {
      float xMax = 0;
      float xMin = mainwidth;
      float yMax = 0;
      float yMin = mainheight;
      float xt, yt;
println(i);
      Polygon2D region = clip.clipPolygon(regionList[i]);

      for (Vec2D v : region.vertices) {
        xt = v.x;
        yt = v.y;

        if (xt < xMin) xMin = xt;
        if (xt > xMax) xMax = xt;
        if (yt < yMin) yMin = yt;
        if (yt > yMax) yMax = yt;
      }

      float xDiff = xMax - xMin;
      float yDiff = yMax - yMin;
      float maxSize = max(xDiff, yDiff);
      float minSize = min(xDiff, yDiff);

      float scaleFactor = 1.0;

      // Maximum voronoi cell extent should be between
      // cellBuffer/2 and cellBuffer in size.

      while (maxSize > cellBuffer) {
        scaleFactor *= 0.5;
        maxSize *= 0.5;
      }

      while (maxSize < (cellBuffer / 2)) {
        scaleFactor *= 2;
        maxSize *= 2;
      }

      if ((minSize * scaleFactor) > (cellBuffer/2)) {
        // Special correction for objects of near-unity (square-like) aspect ratio,
        // which have larger area *and* where it is less essential to find the exact centroid:
        scaleFactor *= 0.5;
      }

      float StepSize = (1/scaleFactor);

      float xSum = 0;
      float ySum = 0;
      float dSum = 0;
      float PicDensity = 1.0;

        for (float x=xMin; x<=xMax; x += StepSize) {
          for (float y=yMin; y<=yMax; y += StepSize) {
            Vec2D p0 = new Vec2D(x, y);
            if (region.containsPoint(p0)) {
              // Thanks to polygon clipping, NO vertices will be beyond the sides of imgblur.
              PicDensity = 0.001 + (brightness(imgblur.pixels[ round(y)*imgblur.width + round(x) ]));

              xSum += PicDensity * x;
              ySum += PicDensity * y;
              dSum += PicDensity;
            }
          }
        }
      

      if (dSum > 0) {
        xSum /= dSum;
        ySum /= dSum;
      }

      Vec2D centr;

      float xTemp = xSum;
      float yTemp = ySum;

      if ((xTemp <= 0) || (xTemp >= mainwidth) || (yTemp <= 0) || (yTemp >= mainheight)) {
        // If new centroid is computed to be outside the visible region, use the geometric centroid instead.
        // This will help to prevent runaway points due to numerical artifacts.
        centr = region.getCentroid();
        xTemp = centr.x;
        yTemp = centr.y;

        // Enforce sides, if absolutely necessary:  (Failure to do so *will* cause a crash, eventually.)

        if (xTemp <= 0) xTemp = 0 + 1;
        if (xTemp >= mainwidth)  xTemp = mainwidth - 1;
        if (yTemp <= 0) yTemp = 0 + 1;
        if (yTemp >= mainheight)  yTemp = mainheight - 1;
      }

      particles[i].x = xTemp;
      particles[i].y = yTemp;

      cellsCalculated++;
    }

      println("cellsCalculated = " + cellsCalculated );
      println("cellsTotal = " + cellsTotal );

    if (cellsCalculated >= cellsTotal) {
      voronoiCalculated = false;
      generation++;
      println("Generation = " + generation );

    }
  }
}

 
void procesar (String archivo) {  
  particleRouteLength = 0;
  generation = 0;
  routeStep = 0;
  voronoiCalculated = false;
  cellsCalculated = 0;
  vorPointsAdded = 0;
  voronoi = new Voronoi();  // Erase mesh
  
  println(archivo);
  float dotScale = (maxDotSize - minDotSize);
  //float cutoffScaled = 1 - cutoff;
  
    particles = new Vec2D[maxParticles];
    imgblur.loadPixels();

  int  i = 0;
  while (i < maxParticles) {
    int fx = floor(random(mainwidth));
    int fy = floor(random(mainheight));
    float p = brightness(imgblur.pixels[ fy*mainwidth + fx])/255; 
    // OK to use simple floor_ rounding here, because  this is a one-time operation,
    // creating the initial distribution that will be iterated.
    //println(i,p,fx,fy,fy*mainwidth + fx,mainwidth,mainheight, maxParticles);


    if (random(1) >= p ) {
      Vec2D p1 = new Vec2D(fx, fy);
      particles[i] = p1;
      i++;
    }
  }
  
  println("Antes de optimizePlotPath()",voronoiCalculated);
  while (generation < topegeneration) {
    optimizePlotPath();
    doPhysics();
    //generation++;
  }
  println("Antes de doPhysics()",voronoiCalculated);

  println("Fin",saveNow);
  
  
  
    fileOutput = loadStrings("header.txt");
    String rowTemp;
        
    float SVGscale = 1; //(800.0 / (float) mainheight);
    int xOffset = 0;//(int)(1600 - (SVGscale * mainwidth / 2));
    int yOffset = 0;//(int)(400 - (SVGscale * mainheight / 2));

      println("Save TSP File (SVG)");

      // Path header::
      rowTemp = "<path style=\"fill:none;stroke:black;stroke-width:2px;stroke-linejoin:round;stroke-linecap:round;\" d=\"M ";
      fileOutput = append(fileOutput, rowTemp);

      for ( i = 0; i < particleRouteLength; ++i) {
        Vec2D p1 = particles[particleRoute[i]];

        float xTemp = SVGscale * p1.x + xOffset;
        float yTemp = SVGscale * p1.y + yOffset;

        rowTemp = xTemp + " " + yTemp + "\r";
        fileOutput = append(fileOutput, rowTemp);
      }
      fileOutput = append(fileOutput, "\" />"); // End path description
 
    // SVG footer:
    fileOutput = append(fileOutput, "</g></g></svg>");
    saveStrings(archivo, fileOutput);

}
