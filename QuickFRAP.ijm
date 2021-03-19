/* Macro written by Mikheil Nanikashvili, University of Edinburgh ,2020
 */

 //Select the Bleached area
run("ROI Manager...");
run("Tile")
waitForUser("Welcome to QuickFRAP.\n" 
+"Please select the bleached region and press Add in the ROI Manager.\n" 
+"Once done press OK")
roiManager("Select", 0);
roiManager("Rename", "Bleached region");

//Select the Unbleached area
waitForUser("Now select the unbleached region to be used as a normaliser and press Add in the ROI Manager. Once done press Ok")
roiManager("Select", 1);
roiManager("Rename", "Unbleached region");

//Select the bacgrkound region
waitForUser("Now select the background region to be used as a normaliser and press Add in the ROI Manager. Once done press Ok")
roiManager("Select", 2);
roiManager("Rename", "Background region");
waitForUser("Please make sure that the Frame interval in the Properties window (Image>Properties) is not 0,\n" 
+"and is set accordingly to your data collection parameters in SECONDS, and press OK in the properties window.\n"
+"Once done press OK")

//Get the post bleach frame
waitForUser("Please note the first POST bleach frame number, and press OK");
post_bleachf = getNumber("Enter the first POST bleach frame number", 1);


//Processing of the Bleached area intensity values vs time
run("Tile");
n_slices = getNumber("Specify up to what frame to fit and plot ", 30);
roiManager("Select", 0)
setSlice(1);
roiManager("Update");
var i=0
while (i < n_slices) {
roiManager("Select", 0);
roiManager("Measure");
run("Next Slice [>]");
roiManager("Update");
  i++;
}
Table.rename("Results","Bleached Region");

//Processing of the UnBleached area intensity values vs time
roiManager("Select", 1)
setSlice(1);
roiManager("Update");
for (i = 0; i < n_slices; i++) {
 roiManager("Select", 1);
roiManager("Measure");
run("Next Slice [>]");
roiManager("Update");
}
Table.rename("Results","UnBleached Region");

//Processing of the Background area intensity values vs time
roiManager("Select", 2)
setSlice(1);
roiManager("Update");
for (i = 0; i < n_slices; i++) {
 roiManager("Select", 2);
roiManager("Measure");
run("Next Slice [>]");
roiManager("Update");
}
Table.rename("Results","Background Region");

//Plot of Unbleached area and Bleached area mean intensity values vs time
Plot.create("Plot of Bleached and Unbleached Regions", "x", "Mean");
Plot.add("Circle", Table.getColumn("Mean", "Bleached Region"));
Plot.setStyle(0, "red,#ff9999,1.0,Circle");
Plot.add("Circle", Table.getColumn("Mean", "UnBleached Region"));
Plot.setStyle(1, "blue,#9999ff,1.0,Circle");
Plot.add("Circle", Table.getColumn("Mean", "Background Region"));
Plot.setStyle(1, "black,#000000,1.0,Circle");

Plot.addLegend("Bleached Region \nUnbleached Region \nBackground Region ", "Bottom-Right");

//Cleaning up 
selectWindow("UnBleached Region"); 
run("Close");
selectWindow("Bleached Region"); 
run("Close");
selectWindow("Background Region"); 
run("Close");
Plot.show()
Plot.showValues

//Prebleach normalisation (first part) (Background column Y2)
y0 = Table.getColumn("Y0");
y1 = Table.getColumn("Y1");
y2 = Table.getColumn("Y2");

b_pre = Array.slice(y0,0,post_bleachf-1);
un_pre = Array.slice(y1,0,post_bleachf-1);
back_pre = Array.slice(y2,0,post_bleachf-1);

Array.getStatistics(b_pre, min, max, mean, stdDev);
b_pre_mean = mean;
Array.getStatistics(un_pre, min, max, mean, stdDev);
un_pre_mean = mean;
Array.getStatistics(back_pre, min, max, mean, stdDev);
back_pre_mean = mean;

b_norm = (b_pre_mean-back_pre_mean);
un_norm = (un_pre_mean - back_pre_mean);

//Background Substraction 

for(var i=0; i<y0.length; i++) {
    y0[i] -= y2[i];
}

for(var i=0; i<y1.length; i++) {
    y1[i] -= y2[i];
}

//Prebleach normalisation (second part)
 
for(var i=0; i<y0.length; i++) {
    y0[i] /= b_norm;
}

for(var i=0; i<y1.length; i++) {
    y1[i] /= un_norm;
}

Table.setColumn("Y0", y0);
Table.setColumn("Y1", y1);


//Correction for fluorescence loss
Table.applyMacro("Y3=Y0/Y1 ");

//Converting frames to seconds
selectImage(1);
Table.applyMacro("X0=X0*Stack.getFrameInterval()");

// Builds an array used for curve fitting
yarray = Table.getColumn("Y3", "Results");
xarray = Table.getColumn("X0", "Results");
indes = Array.rankPositions(yarray);
minindex = indes[0];
maxindex = indes.length;
x = Array.slice(xarray,minindex,maxindex);
y = Array.slice(yarray,minindex,maxindex);

// Adds column names
Table.renameColumn("X0", "Time");
Table.renameColumn("Y0", "Bleached ROI (pre-bleach+backg normalised)");
Table.renameColumn("Y1", "Unbleached ROI (pre-bleach+backg normalised)");
Table.renameColumn("Y2", "Background ROI");
Table.renameColumn("Y3", "Normalised");

//Fit the exponential recovery curve
Fit.logResults;
Fit.doFit("Exponential recovery", x, y);
mobile = Fit.p(0);
tau = Fit.p(1);
Fit.plot;
Plot.setFontSize(0.0);
Plot.setAxisLabelSize(12.0, "plain");
Plot.setXYLabels("Time (Seconds)", "NU");

//Calculates FRAP parameters
immobile = 1-mobile;
half_life = Math.log(0.5)/-tau;
IJ.log("Mobile Fraction = " + mobile);
IJ.log("Immobile Fraction = " + immobile);
IJ.log("Half life = " + half_life);
