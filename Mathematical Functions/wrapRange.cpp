/*WRAPRANGE A C++ implementation of an algorithm to bound values to a
 *          specific range, wrapping around if the value is outside the
 *          range. The parameter mirrorWrap determines how the wrapping is
 *          performed. For example, if mirrorWrap=false, minBound=-pi and
 *          maxBound=pi, then a value that is some eps above pi will be
 *          wrapped to a value some eps above -pi.  Similarly, a value some
 *          eps below -pi is wrapped to a value some eps above -pi. On the
 *          other hand, if mirrorWrap==true,    then leaving the region of
 *          [minBound,maxBound] goes the other  way. For example, if
 *          mirrorWrap=true, minBound=-pi/2, and    maxBound=pi/2, then a
 *          value that is some eps above pi/2 will  be mapped to a point
 *          some eps below pi/2 and a value some eps below -pi/2 will be
 *          mapped to a point some eps above -pi/2.
 *
 *INPUTS: vals  An vector or matrix of real values that should be wrapped
 *             to the range minBound->maxBound.
 *    minBound The lower scalar bound of the output parameters.
 *    maxBound A value > minBound that is the upper bound to the allowable
 *             range of output values.
 *  mirrorWrap A value that determines whether a values outside the bounds
 *             maps back into the valid region offset to the bound that it
 *             passed or offset to the other boundary. If this parameter is
 *             omitted, then mirrorWrap=false is assumed and the function
 *             behaves similar to a shifted modulo function.
 *
 *OUTPUTS: wrapVals  The set of vals wrapped such that
 *                  minBound<=wrapVals<maxBound.
 *
 *Additional comments on the function are given in the Matlab version
 *wrapRange.m
 *
 *December 2014 David F. Crouse, Naval Research Laboratory, Washington D.C.*/
/*(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.*/

#include "matrix.h"
/*This header is required by Matlab.*/
#include "mex.h"
#include "MexValidation.h"
#include "mathFuncs.hpp"
#include <cmath>

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    size_t i, numRows,numCols, numEls;
    double minBound, maxBound, *vals, *wrapVals;
    mxArray *retMat;
    bool mirrorWrap=false;
    
    
    if(nrhs<3){
        mexErrMsgTxt("Not enough inputs.");
        return;
    }
    
    if(nrhs>4) {
        mexErrMsgTxt("Too many inputs.");
        return;
    }
    
    if(nlhs>1) {
        mexErrMsgTxt("Too many outputs.");
        return;
    }
    
    checkRealDoubleArray(prhs[0]);
    numRows=mxGetM(prhs[0]);
    numCols=mxGetN(prhs[0]);
    numEls=numRows*numCols;
    
    //If given an empty matrix, return an empty matrix.
    if(numEls==0) {
        plhs[0]=mxCreateDoubleMatrix(0,0,mxREAL);
        return;
    }
    
    vals=(double*)mxGetData(prhs[0]);
    
    minBound=getDoubleFromMatlab(prhs[1]);
    maxBound=getDoubleFromMatlab(prhs[2]);
    
    if(maxBound<=minBound) {
        mexErrMsgTxt("the maximum bound must be less than the minimum bound.");
    }
    
    if(nrhs>3) {
        mirrorWrap=getBoolFromMatlab(prhs[3]);
    }
    
    //Allocate space for the return values.
    retMat=mxCreateDoubleMatrix(numRows,numCols,mxREAL);
    wrapVals=(double*)mxGetData(retMat);
    
    if(mirrorWrap) {
        for(i=0;i<numEls;i++) {
            wrapVals[i]=wrapRangeMirrorCPP(vals[i],minBound,maxBound);
        }
    } else {
       for(i=0;i<numEls;i++) {
            wrapVals[i]=wrapRangeCPP(vals[i],minBound,maxBound);
        }
    }
    
    plhs[0]=retMat;
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
