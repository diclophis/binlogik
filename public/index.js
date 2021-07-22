/* */


var defaultPollTimeout = 2000;
var pollTimeout = defaultPollTimeout;

var handleErrors = function(response) {
  if (!response.ok) {
    throw Error(response.statusText);
  }
  return response;
}

var resetTimeout = function() {
  if (typeof(window.gameLoopTimeout) != "undefined") {
    clearTimeout(window.gameLoopTimeout);
  }
};

var keepTimeout = function() {
  resetTimeout();

  window.gameLoopTimeout = setTimeout(() => {
    refreshIndex();
  }, pollTimeout);
};

/*

var pointZero = Date.now();

var allPoints = [];
var lastTime = pointZero;
var halted = false;
var globalScale = 1.0; //0.1;
var windowScale = 1.0;
var graphSize = [1024.0, 256.0];
var graphDatum = [0, 0];
var graphCentrum = [0, 0];
var elapsedTime = 0.0;

var path = document.createElementNS("http://www.w3.org/2000/svg", 'path');
path.setAttribute('stroke', "blue");

var basePath = document.createElementNS("http://www.w3.org/2000/svg", 'path');
basePath.setAttribute('stroke', "black");

var pathGroup = document.createElementNS("http://www.w3.org/2000/svg", 'g');
pathGroup.setAttribute("transform", `scale(1, -1)`);
pathGroup.appendChild(path);
pathGroup.appendChild(basePath);

var svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
svg.setAttribute("width", graphSize[0]);
svg.setAttribute("height", graphSize[1]);
svg.setAttribute("preserveAspectRatio", "none");
svg.setAttribute("version", "1.1");
svg.setAttribute("aria-hidden", "true");
svg.appendChild(pathGroup);


// <text x="20" y="35" class="small">My</text>
var lastPointLabel = document.createElementNS("http://www.w3.org/2000/svg", 'text');
lastPointLabel.setAttribute("x", 100);
lastPointLabel.setAttribute("y", 100);
var textNode = document.createTextNode("foo");
lastPointLabel.appendChild(textNode);

svg.appendChild(lastPointLabel);

var haltButton = document.createElement('button');
haltButton.innerText = "halt";
haltButton.addEventListener('click', function() {
  halted = !halted;
});

var zoomOutButton = document.createElement('button');
zoomOutButton.innerText = "-";
zoomOutButton.addEventListener('click', function() {
  globalScale *= 1.1;
});

var zoomInButton = document.createElement('button');
zoomInButton.innerText = "+";
zoomInButton.addEventListener('click', function() {
  globalScale *= 0.9;
});

var panLeftButton = document.createElement('button');
panLeftButton.innerText = "<<";
panLeftButton.addEventListener('click', function() {
  graphDatum[0] -= (2.0 * (1.0 / globalScale));
});

var panRightButton = document.createElement('button');
panRightButton.innerText = ">>";
panRightButton.addEventListener('click', function() {
  graphDatum[0] += (2.0 * (1.0 / globalScale));
});

document.body.appendChild(svg);
document.body.appendChild(haltButton);
document.body.appendChild(zoomOutButton);
document.body.appendChild(zoomInButton);
document.body.appendChild(panLeftButton);
document.body.appendChild(panRightButton);

var debugSpan = document.createElement("span");
document.body.appendChild(debugSpan);

path.setAttribute("fill", "none");
//path.setAttribute("shape-rendering", "crispEdges");

var pointsToPath = function() {
  var d = ``;

  var lastPoint = null;
  
  for (var i=0; i<allPoints.length; i+=1) {
    var point = allPoints[i];

    var cx = (point[0]);
    var cy = (point[1]);

    if (lastPoint) {
      var lx = (lastPoint[0]);
      var ly = (lastPoint[1]);
      d += `L ${cx} ${cy} `;
    } else {
      d += `M ${cx} ${cy} `;
    }

    lastPoint = point;
  }

  return d;
}

var plotWindow = function() {
  path.setAttribute('d', pointsToPath());

  var rx = graphDatum[0] + (graphSize[0] * 0.5);
  var lx = (rx - (graphSize[0]));
  var sw = graphSize[0];

  var centerBitsX1 = (-(((0.5 * (graphSize[0]) * globalScale)))) + (graphDatum[0] * globalScale);
  var centerBitsX2 = (centerBitsX1 + (graphSize[0] * globalScale)) + (graphDatum[1] * globalScale);
  var centerBitsY = 0;

  var d = ``;
  var heightScale = 20.0;
  
  for (var i=-4; i<5; i+=1) {
    d += `M ${centerBitsX1} ${centerBitsY + (i * heightScale)} L ${centerBitsX2} ${centerBitsY + (i * heightScale)} `;
  }
  
  let bitBop = (((centerBitsX2 - centerBitsX1) * 0.5) + (graphDatum[0] * globalScale)) - (graphSize[0] * 0.5 * globalScale);

  d += `M ${bitBop} ${-100} L ${bitBop} ${100} `;

  //basePath is center line origin datum
  basePath.setAttribute('d', d);

  //TODO: draw vertical grid lines

  //min-x, min-y, width and height
  let vbMinX = ((graphDatum[0] * (globalScale)) - (graphSize[0] * 0.5 * globalScale));
  let vbMinY = ((graphDatum[1] * globalScale) - (graphSize[1] * 0.5 * globalScale));
  let vbWidth = ((graphSize[0] * 1.0) * globalScale);
  let vbHeight = (((graphSize[1] * 1.0) * globalScale));

  svg.setAttribute("viewBox", `${parseInt(vbMinX)} ${parseInt(vbMinY)} ${parseInt(vbWidth)} ${parseInt(vbHeight)}`);

  path.setAttribute("stroke-width", 1.0 * globalScale);
  basePath.setAttribute("stroke-width", 1.0 * globalScale);
};


var redrawRender = function() {
  if (allPoints.length > 256) {
    allPoints.splice(0, 32); //all: [0, allPoints.length];
  }

  var globalTime = Date.now();
  var frameTime = globalTime - lastTime;

  elapsedTime += frameTime;
  lastTime = globalTime;

  let timeShift = (Date.now() - pointZero);
  let keepUpShift = ((frameTime / 1000.0) * (1.0 / globalScale));
  let timeScale = 100.0; //1500.0;

  graphDatum[0] += keepUpShift * timeScale;

  if (!halted) {
    var newPointR = [];
    newPointR[0] = (timeShift / 1000.0) * timeScale; //((Math.random() * 100.0) - 50.0) + (timeShift);
    ////newPointR[0] = (Math.sin(globalTime * 0.033) * 100.0); //((Math.random() * 100.0) - 50.0) + (timeShift);
    ////newPointR[1] = (Math.random() * 300.0) - 150.0;
    newPointR[1] = (Math.sin(globalTime * 0.01) * 100.0);
    allPoints.push(newPointR);
  }

  plotWindow();
  elapsedTime = 0.0;

  window.requestAnimationFrame(redrawRender);
};


redrawRender();
*/

import uPlot from './uPlot.esm.js';

function wheelZoomPlugin(opts) {
  let factor = opts.factor || 0.75;

  let xMin, xMax, yMin, yMax, xRange, yRange;

  function clamp(nRange, nMin, nMax, fRange, fMin, fMax) {
    if (nRange > fRange) {
      nMin = fMin;
      nMax = fMax;
    }
    else if (nMin < fMin) {
      nMin = fMin;
      nMax = fMin + nRange;
    }
    else if (nMax > fMax) {
      nMax = fMax;
      nMin = fMax - nRange;
    }

    return [nMin, nMax];
  }

  return {
    hooks: {
      ready: u => {
        xMin = u.scales.x.min;
        xMax = u.scales.x.max;
        yMin = u.scales.y.min;
        yMax = u.scales.y.max;

        xRange = xMax - xMin;
        yRange = yMax - yMin;

        let over = u.over;
        let rect = over.getBoundingClientRect();

        // wheel drag pan
        over.addEventListener("mousedown", e => {
          if (e.button == 1) {
          //  plot.style.cursor = "move";
            e.preventDefault();

            let left0 = e.clientX;
          //  let top0 = e.clientY;

            let scXMin0 = u.scales.x.min;
            let scXMax0 = u.scales.x.max;

            let xUnitsPerPx = u.posToVal(1, 'x') - u.posToVal(0, 'x');

            function onmove(e) {
              e.preventDefault();

              let left1 = e.clientX;
            //  let top1 = e.clientY;

              let dx = xUnitsPerPx * (left1 - left0);

              u.setScale('x', {
                min: scXMin0 - dx,
                max: scXMax0 - dx,
              });
            }

            function onup(e) {
              document.removeEventListener("mousemove", onmove);
              document.removeEventListener("mouseup", onup);
            }

            document.addEventListener("mousemove", onmove);
            document.addEventListener("mouseup", onup);
          }
        });

        // wheel scroll zoom
        over.addEventListener("wheel", e => {
          e.preventDefault();

          let {left, top} = u.cursor;

          let leftPct = left/rect.width;
          let btmPct = 1 - top/rect.height;
          let xVal = u.posToVal(left, "x");
          let yVal = u.posToVal(top, "y");
          let oxRange = u.scales.x.max - u.scales.x.min;
          let oyRange = u.scales.y.max - u.scales.y.min;

          let nxRange = e.deltaY < 0 ? oxRange * factor : oxRange / factor;
          let nxMin = xVal - leftPct * nxRange;
          let nxMax = nxMin + nxRange;
          [nxMin, nxMax] = clamp(nxRange, nxMin, nxMax, xRange, xMin, xMax);

          let nyRange = e.deltaY < 0 ? oyRange * factor : oyRange / factor;
          let nyMin = yVal - btmPct * nyRange;
          let nyMax = nyMin + nyRange;
          [nyMin, nyMax] = clamp(nyRange, nyMin, nyMax, yRange, yMin, yMax);

          u.batch(() => {
            u.setScale("x", {
              min: nxMin,
              max: nxMax,
            });

            u.setScale("y", {
              min: nyMin,
              max: nyMax,
            });
          });
        });
      }
    }
  };
}


/*
let wait = document.getElementById("wait");
wait.textContent = "Fetching data.json (2.07MB)....";
fetch("../bench/data.json").then(r => r.json()).then(packed => {
  wait.textContent = "Rendering...";
  let data = prepData(packed);
  setTimeout(() => makeChart(data), 0);
});
*/

/*
setInterval(function() {
  start1 += 10;
  let data1 = sliceData(start1, start1 + len1);
  uplot1.setData(data1);
}, interval);
*/

//let data = [7, "epoch", "idl", "recv", "send", "writ", "used", "free", 26107560, 99.46, 0, 0, 0.63, 614.52, 3767.67];

var counterChart = null;

function makeChart() {
  let opts = {
    title: "Wheel Zoom & Drag",
    width: 600,
    height: 400,
    plugins: [
      wheelZoomPlugin({factor: 0.75})
    ],
    scales: {
      x: {
        auto: true,
      },
      'counter': {
        auto: true,
      }
    },
    series: [
      {},
      {
        label: "Counter",
        stroke: "red",
      },
    ]
  };

/*
  const data = [
    [ 1, 2, 3, 4, 5, 6, 7],
    [40,43,60,65,71,73,80],
    [18,24,37,55,55,60,63],
  ];
  */

  counterChart = new uPlot(opts, [], document.body);
}

makeChart();

var refreshIndex = function() {
  //allPoints.splice(0, allPoints.length);
  //keepTimeout();
  //return;

  var req = new Request('http://localhost:9292/', {
    method: 'GET'
  });

  fetch(req)
  .then(handleErrors)
  .then(response => {
    pollTimeout = defaultPollTimeout;
    return response.json()
  })
  .then(tsdbContexts => {
    let globalCounterTsdb = tsdbContexts["global.counter"];

    counterChart.setData(globalCounterTsdb);

    //var globalTime = Date.now();

    //var frameTime = globalTime - lastTime;

    //elapsedTime += frameTime;
    //lastTime = globalTime;

    //let timeShift = (Date.now() - pointZero);
    //let keepUpShift = ((frameTime / 1000.0) * (1.0 / globalScale)); // + (frameTime * 0.1));

    //graphDatum[0] += keepUpShift * 1.0;

    //if (!halted) {
    //  //allPoints = [];
    //  //allPoints.splice(0, allPoints.length);

    //  //var newPointR = [];
    //  //newPointR[0] = (timeShift / 1000.0) * 100.0; //((Math.random() * 100.0) - 50.0) + (timeShift);
    //  ////newPointR[0] = (Math.sin(globalTime * 0.033) * 100.0); //((Math.random() * 100.0) - 50.0) + (timeShift);
    //  ////newPointR[1] = (Math.random() * 300.0) - 150.0;
    //  //newPointR[1] = (Math.sin(globalTime * 10.0) * 100.0);
    //  //allPoints.push(newPointR);

    //  //globalCounterTsdb.forEach(foop => {

    //    //let foop = globalCounterTsdb[globalCounterTsdb.length - 1];

    //    //let timeStamp = foop[0] * 1000.0;
    //    //let metric = foop[1];

    //    //var newPoint = [];
    //    //newPoint[0] = ((globalTime - timeStamp) / 1000.0) * 1.0;
    //    //newPoint[1] = (metric * 0.0000001);
    //    //allPoints.push(newPoint);
    //    //console.log(globalTime, newPoint[0], newPoint[1]);

    //    //var newPointR = [];
    //    //newPointR[0] = (timeShift / 1000.0); //((Math.random() * 100.0) - 50.0) + (timeShift);
    //    ////newPointR[0] = (Math.sin(globalTime * 0.033) * 100.0); //((Math.random() * 100.0) - 50.0) + (timeShift);
    //    ////newPointR[1] = (Math.random() * 300.0) - 150.0;
    //    ////newPointR[1] = (Math.sin(globalTime * 0.1) * metric) * 0.00001;
    //    //newPointR[1] = 100.0; //metric * 0.00001;
    //    //allPoints.push(newPointR);
    //  //});
    //}

    //plotWindow();
    //elapsedTime = 0.0;

    keepTimeout();
  });
};

refreshIndex();

