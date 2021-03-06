/**DIRECTGEODETICPROBGEN Solve the direct geodetic problem. That is, given
 *                     an initial point and an initial bearing an
 *                     ellipsoidal Earth, find the end point and final
 *                     bearing if one were to travel one or more given
 *                     distances along a geodesic curve (the shortest curve
 *                     between two points on a curved surface).
 *
 *INPUTS:latLonStart A 2XN matrix of the N initial points given in geodetic
 *                  latitude and longitude in radians of the format
 *                  [latitude;longitude] for each column (point). The
 *                  latitude must be between -pi/2 and pi/2 radians and the
 *                  longitude between -pi and pi radians.
 *        azStart   An NX1 or 1XN vector of the forward azimuth (initial
 *                  headings) at the starting point in radians East of true
 *                  North on the reference ellipsoid.
 *          dist    An NX1 or 1XN vector of the distances in meters 
 *                  that will be traveled on the geodesic curve starting at
 *                  latLonStart with initial heading azStart where
 *                  solutions are desired.
 *          a       The semi-major axis of the reference ellipsoid (in
 *                  meters). If this argument is omitted, the value in
 *                  Constants.WGS84SemiMajorAxis is used.
 *          f       The flattening factor of the reference ellipsoid. If
 *                  this argument is omitted, the value in
 *                  Constants.WGS84Flattening is used.
 *
 *OUTPUTS:latLonEnd  A2XN matrix of geodetic latitude and longitudes of the
 *                  final points of the geodesic trajectory given in
 *                  radians as [latitude;longitude].
 *       azEnd      An NX1 vector of rhe forward azimuth (bearing) at the
 *                  ending points in radians East of true North on the
 *                  reference ellipsoid.
 *
 *The function is essentially a Matlab interface for the implementation in
 *GeographicLib, which is documented in 
 *The algorithm initially solves the indirect geodetic problem on the
 *surface of the reference ellipsoid using the function geoddistance from
 *C. F. F. Karney. (2013, 2 Jul.) Geodesics on an ellipsoid of revolution.
 *Matlab Central. [Online].
 *Available: http://www.mathworks.com/matlabcentral/fileexchange/39108
 *and
 *C. F. F. Karney, "Algorithms for geodesics," Journal of Geodesy, vol. 87,
 *no. 1, pp. 43?45, Jan. 2013. [Online].
 *Available: http://arxiv.org/pdf/1109.4448.pdf
 *and 
 *C. F. F. Karney. (2013, 31 Aug.) Addenda and errata for papers on
 *geodesics. [Online].
 *Available: http://geographiclib.sourceforge.net/geod-addenda.html
 *and 
 *C. F. F. Karney. (2011, 7 Feb.) Geodesics on an ellipsoid of revolution.
 *[Online]. Available: http://arxiv.org/pdf/1102.1215.pdf
 *
 *The algorithm can be compiled for use in Matlab using the 
 *CompileCLibraries function.
 *
 *The algorithm is run in Matlab using the command format
 *[latLonEnd,azEnd]=directGeodeticProb(latLonStart,azStart,dist);
 *or if something other than the WGS84 reference ellipsoid is used
 *[latLonEnd,azEnd]=directGeodeticProb(latLonStart,azStart,dist,a,f);
 *
 *April 2015 David F. Crouse, Naval Research Laboratory, Washington D.C.
 */
/*(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.*/

/*This header is required by Matlab.*/
#include "mex.h"
#include "MexValidation.h"

//For the wrapRange function so that there is no issue if latitudes and
//longitudes are given outside of the valid range for the GeographicLib
//functions.
#include "mathFuncs.hpp"

//For fabs
#include <cmath>

#include <GeographicLib/Geodesic.hpp>
#include <GeographicLib/GeodesicExact.hpp>

using namespace GeographicLib;

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    size_t numPoints;
    const double pi=3.1415926535897932384626433832795;
    double *latLonStart, *azStart, *dist;
    double a,f;
    mxArray *latLonEndMATLAB, *azEndMATLAB;
    double *latLonEnd, *azEnd;
    
    if(nrhs<3||nrhs>5){
        mexErrMsgTxt("Wrong number of inputs");
    }

    if(nlhs>2) {
        mexErrMsgTxt("Wrong number of outputs.");
    }
    
    checkRealDoubleArray(prhs[0]);
    checkRealDoubleArray(prhs[1]);
    checkRealDoubleArray(prhs[2]);
    
    {
        size_t numRow;
        numRow = mxGetM(prhs[0]);
        numPoints = mxGetN(prhs[0]);
        
        if(numRow!=2) {
            mexErrMsgTxt("The latLonStart vector has a bad dimensionality.");
        }
        
        if((mxGetM(prhs[1])*mxGetN(prhs[1]))!=numPoints) {
            mexErrMsgTxt("The azStart vector has a bad dimensionality.");
        }
        
        if((mxGetM(prhs[2])*mxGetN(prhs[2]))!=numPoints) {
            mexErrMsgTxt("The dist vector has a bad dimensionality.");
        }
    }
    
    //Get the primary inputs
    latLonStart=(double*)mxGetData(prhs[0]);
    azStart=(double*)mxGetData(prhs[1]);
    dist=(double*)mxGetData(prhs[2]);
            
    if(nrhs>3) {
        a=getDoubleFromMatlab(prhs[3]);
        
    } else {
        a=getScalarMatlabClassConst("Constants","WGS84SemiMajorAxis");
    }

    if(nrhs>4) {
        f=getDoubleFromMatlab(prhs[4]);
    } else {
        f=getScalarMatlabClassConst("Constants","WGS84Flattening");
    }
    
    //Allocate space for the return variables.
    latLonEndMATLAB=mxCreateDoubleMatrix(2,numPoints,mxREAL);
    azEndMATLAB=mxCreateDoubleMatrix(numPoints,1,mxREAL);
    
    latLonEnd=(double*)mxGetData(latLonEndMATLAB);
    azEnd=(double*)mxGetData(azEndMATLAB);
    
    //Solve the indirect geodetic problem for each of the point pairs.
    //The class used to solve the problem is chosen based on the value of
    //f. As per the documentation is GeographicLib, the Geodesic class is
    //best suited for problems where |f|<=0.01. For other problems, the
    //GeodesicExact class is the better choice.
    
    if(fabs(f)<=0.01) {
        Geodesic geod(a, f);
        size_t curPoint,curBaseIdx;
        
        curBaseIdx=0;
        for(curPoint=0;curPoint<numPoints;curPoint++) {
            //The function takes the values in degrees.
            const double lat1=wrapRangeMirrorCPP(latLonStart[curBaseIdx]*(180.0/pi),-90.0,90.0);
            const double lon1=wrapRangeCPP(latLonStart[curBaseIdx+1]*(180.0/pi),-180.0,180.0);
            const double az1=wrapRangeCPP(azStart[curPoint]*(180.0/pi),-180.0,180.0);
            const double s12=dist[curPoint];
            double lat2, lon2, azi2;

            geod.Direct(lat1,lon1,az1,s12,lat2,lon2,azi2);
            
            latLonEnd[curBaseIdx]=lat2*(pi/180.0);
            latLonEnd[curBaseIdx+1]=lon2*(pi/180.0);
            azEnd[curBaseIdx]=azi2*(pi/180.0);
                    
            curBaseIdx+=2;
        }
    } else {
        GeodesicExact geod(a, f);
        size_t curPoint,curBaseIdx;
        
        curBaseIdx=0;
        for(curPoint=0;curPoint<numPoints;curPoint++) {
            //The function takes the values in degrees.
            const double lat1=latLonStart[curBaseIdx]*(180.0/pi);
            const double lon1=latLonStart[curBaseIdx+1]*(180.0/pi); 
            const double az1=azStart[curPoint];
            const double s12=dist[curPoint];
            double lat2, lon2, azi2;
                    
            geod.Direct(lat1,lon1,az1,s12,lat2,lon2,azi2);
            
            latLonEnd[curBaseIdx]=lat2*(pi/180.0);
            latLonEnd[curBaseIdx+1]=lon2*(pi/180.0);
            azEnd[curBaseIdx]=azi2*(pi/180.0);
                    
            curBaseIdx+=2;
        }
    }
    
    //Set the return values.
    plhs[0]=latLonEndMATLAB;

    if(nlhs>1) {
        plhs[1]=azEndMATLAB;
    } else {
        mxDestroyArray(azEndMATLAB);
    }
}

/*LICENSE:
%
%The source code is in the public domain and not licensed or under
%copyright. The information and software may be used freely by the public.
%As required by 17 U.S.C. 403, third parties producing copyrighted works
%consisting predominantly of the material produced by U.S. government
%agencies must provide notice with such work(s) identifying the U.S.
%Government material incorporated and stating that such material is not
%subject to copyright protection.
%
%Derived works shall not identify themselves in a manner that implies an
%endorsement by or an affiliation with the Naval Research Laboratory.
%
%RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF THE
%SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY THE NAVAL
%RESEARCH LABORATORY FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE ACTIONS
%OF RECIPIENT IN THE USE OF THE SOFTWARE.*/
