/**ASSIGN2D  A C++ code (for Matlab) implementation of the shortest path
 *           assignment algorithm to solve the two-dimensional assignment
 *           problem with a rectangular cost matrix C. This implementation
 *           scans the cost matrix by row rather than by column.
 *
 *INPUTS:   C           A numRowXnumCol cost matrix that does not contain
 *                      any NaNs and where the largest finite element minus
 *                      the smallest element is a finite quantity (does not
 *                      overflow) when performing minimization and where
 *                      the smallest finite element minus the largest
 *                      element is finite when performing maximization. 
 *                      Forbidden assignments can be given costs of +Inf
 *                      for minimization and -Inf for maximization.
 *          maximize    If true, the minimization problem is transformed
 *                      into a maximization problem. The default if this
 *                      parameter is omitted is false.
 *
 *OUTPUTS:  col4row     A numRowX1 Matlab vector where the entry in each
 *                      element is an assignment of the element in that row
 *                      to a column. 0 entries signify unassigned rows.
 *          row4col     A numColX1 vector where the entry in each element
 *                      is an assignment of the element in that column to a
 *                      row. 0 entries signify unassigned columns.
 *          gain        The sum of the values of the assigned elements in
 *                      C.
 *          u           The dual variable for the columns.
 *          v           The dual variable for the rows.
 *
 *DEPENDENCIES: ShortestPathCPP.hpp
 *              ShortestPathCPP.cpp
 *              MexValidation.h
 *              mex.h
 *              <algorithm>
 *
 * Note that the dual variables produced by a shortest path assignment
 * algorithm that scans by row are not interchangeable with those of a
 * shortest path assignment algorithm that scans by column. Matlab stores
 * matrices row-wise.
 *
 * The algorithm is described in detail in 
 * D. F. Crouse, "Advances in displaying uncertain estimates of multiple
 * targets," in Proceedings of SPIE: Signal Processing, Sensor Fusion, and
 * Target Recognition XXII, vol. 8745, Baltimore, MD, Apr. 2013.
 *
 *Note that the dual variables produced by a shortest path assignment
 *algorithm that scans by row are not interchangeable with those of a
 *shortest path assignment algorithm that scans by column. Matlab stores
 *matrices row-wise. Additionally, the dual variables are only valid for
 *the transformed cost matrix on which optimization is actually performed,
 *which is not necessarily the original cost matrix provided.
 *
 *When performing minimization with all positive array elements, the
 *initial preprocessing step only changes the returned dual variables by
 *offsetting the u values by -min(min(C)). Adding min(min(C)) to the
 *returned u values, one can get what the dual variables would have been
 *without the preprocessing step.
 *
 * The algorithm can be compiled for use in Matlab  using the 
 * CompileCLibraries function.
 *
 * The algorithm is run in Matlab using the command format
 * [col4row,row4col,gain,u,v]=assign2D(C,maximize)
 *
 *November 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.
 */
/*(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.*/

/*This header is required by Matlab*/
#include "mex.h"
/*This is needed for copy and swap*/
#include <algorithm>
/* This header validates inputs and includes a header needed to handle
 * Matlab matrices.*/
#include "MexValidation.h"
#include "ShortestPathCPP.hpp"

using namespace std;

void mexFunction(const int nlhs, mxArray *plhs[], const int nrhs, const mxArray *prhs[]) {
    size_t numRow,numCol;
    mxArray *CMat, *col4rowMATLAB, *row4colMATLAB,*uMATLAB,*vMATLAB;//These will hold the values to be returned.
    ScratchSpace workMem;//Scratch space needed for the assignment algorithm.
    MurtyHyp *problemSol;//To hold the return value of the C-function called.
    bool didFlip=false;
    bool maximize=false;
    
    if(nrhs<1){
        mexErrMsgTxt("Not enough inputs.");
    }
    
    if(nrhs==2){
        maximize=getBoolFromMatlab(prhs[1]);
    }
    
    if(nrhs>2) {
        mexErrMsgTxt("Too many inputs.");
    }
    
    if(nlhs>5) {
        mexErrMsgTxt("Too many outputs.");
    }
    
    /*Verify the validity of the assignment matrix.*/
    checkRealDoubleArray(prhs[0]);
    /* Get the dimensions of the input data and the pointer to the matrix.
     * It is assumed that the matrix is not so large in M or N as to cause
     * an overflow when using a SIGNED integer data type.*/
    numRow = mxGetM(prhs[0]);
    numCol = mxGetN(prhs[0]);

    /* Transpose the matrix, if necessary, so that the number of row is
     * >= the number of columns.*/
    if(numRow>=numCol) {
        //This is freed using mxDestroyArray
        CMat=mxDuplicateArray(prhs[0]);
    } else {
        swap(numRow,numCol);
        
        //This is freed using mxDestroyArray
        CMat=mxCreateDoubleMatrix(numCol,numRow,mxREAL);
        mexCallMATLAB(1, &CMat, 1,  (mxArray **)&prhs[0], "transpose");
        didFlip=true;
    }
    
    //Allocate scratch space.
    workMem.init(numRow,numCol);
    //Allocate space for the return variables from the called function
    problemSol=new MurtyHyp(numRow, numCol);

    //Allocate space for the return variables to Matlab.
    col4rowMATLAB = allocSignedSizeMatInMatlab(numRow,1);
    row4colMATLAB = allocSignedSizeMatInMatlab(numCol,1);

    uMATLAB = mxCreateNumericMatrix(numCol,1,mxDOUBLE_CLASS,mxREAL);
    vMATLAB = mxCreateNumericMatrix(numRow,1,mxDOUBLE_CLASS,mxREAL);
    
    /*The assignment algorithm returns a nonzero value if no valid
     * solutions exist.*/    
    assign2D(numRow,
             numCol,
             maximize,
             (double*)mxGetData(CMat),
             workMem,
             problemSol);
   
    mxDestroyArray(CMat);
    
    /*Convert C++ indices to Matlab indices*/
    for_each(problemSol->row4col, problemSol->row4col+numCol, increment<ptrdiff_t>);
    for_each(problemSol->col4row, problemSol->col4row+numRow, increment<ptrdiff_t>);
    
    /*Copy the results into the return variables*/
    copy(problemSol->row4col,problemSol->row4col+numCol,(ptrdiff_t*)mxGetData(row4colMATLAB));
    copy(problemSol->col4row,problemSol->col4row+numRow,(ptrdiff_t*)mxGetData(col4rowMATLAB));
    copy(problemSol->u,problemSol->u+numCol,(double*)mxGetData(uMATLAB));
    copy(problemSol->v,problemSol->v+numRow,(double*)mxGetData(vMATLAB));
    
    /* If a transposed array was used */
    if(didFlip==true) {
        swap(numRow,numCol);
        swap(row4colMATLAB,col4rowMATLAB);
        swap(uMATLAB,vMATLAB);
    }

    //Let Matlab know that these are the return variables.
    switch(nlhs) {
        case 5:
            plhs[4]=vMATLAB;
        case 4:
            plhs[3]=uMATLAB;
        case 3:
            plhs[2]=mxCreateDoubleMatrix(1,1,mxREAL);
            *(double*)mxGetData(plhs[2])=problemSol->gain;
        case 2:
            plhs[1]=row4colMATLAB;
        default:
            plhs[0]=col4rowMATLAB;
    }
    
    delete problemSol;
    /* Return variables that are not requested and returned will be
     * automatically freed by Matlab when this function exits.*/
    return;
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
