function [xPred, SPred, xPropCenPoints]=sqrtDiscCubKalPred(xPrev,SPrev,f,SQ,xi,w,stateDiffTrans,stateAvgFun,stateTrans)
%%SQRTDISCCUBKALPRED  Perform the discrete-time prediction step that comes  
%                     with the square root implementation of the cubature
%                     Kalman filter with additive process noise.
%
%INPUTS:    xPrev   The xDim X 1 state estimate at the previous time-step.
%           SPrev   The xDim X xDim lower-triangular square root of the 
%                   state covariance matrix at the previous time-step.
%           f       A function handle for the state transition function
%                   that takes the state as its parameter.
%           SQ      The xDimX xDim lower-triangular square root of the 
%                   process noise covariance matrix.
%           xi      An xDim X numCubPoints matrix of cubature points.        
%           w       A numCubPoints X 1 vector of the weights associated
%                   with the cubature points.
% stateDiffTrans    An optional function handle that takes an xDimXN matrix
%                   of N differences between states estimates and
%                   transforms them however might be necessary. For
%                   example, a state continaing angular components will
%                   generally need differences between angular components
%                   wrapped to the range +/-pi.
%    stateAvgFun    An optional function that given an xDimXN matrix of N
%                   state estimates and an NX1 vector of weights, provides
%                   the weighted average of the state estimates. This is
%                   necessary if, for example, states with angular
%                   components are averaged.
%     stateTrans    An optional function that takes a state estimate and
%                   transforms it. This is useful if one wishes the
%                   elements of the state to be bound to a certain domain.
%                   For example, if an element of the state is an angle,
%                   one should generally want to bind it to the region
%                   +/-pi.
%  xPropCenPoints   The centered propagated cubature state points. This
%                   matrix is needed if the backwards smoothing step is
%                   being applied.
%
%OUTPUTS:   xPred   The xDim X 1 predicted state estimate.
%           SPred   The xDim X xDim lower-triangular predicted state 
%                   covariance estimate.
%
%The mathematics behind the function sqrtDiscCubKalPred are described in 
%more detail in Section IX of
%David F. Crouse , "Basic tracking using nonlinear 3D monostatic and
%bistatic measurements," IEEE Aerospace and Electronic Systems Magazine,
%vol. 29, no. 8, Part II, pp. 4-53, Aug. 2014.
%
%October 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

    if(nargin<7)
        stateDiffTrans=@(x)x;
    end
    
    if(nargin<8)
        stateAvgFun=@(x,w)calcMixtureMoments(x,w);
    end
    
    if(nargin<9)
        stateTrans=@(x)x;
    end
    
    xDim=length(xPrev);
    numCubPoints=length(w);
    
    xPropPoints=zeros(xDim,numCubPoints);%Allocate space

    %Calculate the cubature state points
    xPoints=stateTrans(transformCubPoints(xi,xPrev,SPrev));

    %Propagate the cubature state points
    for curP=1:numCubPoints
        xPropPoints(:,curP)=f(xPoints(:,curP));
    end

    %Calculate the predicted state
    xPred=stateAvgFun(xPropPoints,w);

    %Centered, propagated cubature state points
    xDiff=stateDiffTrans(bsxfun(@minus,xPropPoints,xPred));
    xPropCenPoints=bsxfun(@times,xDiff,sqrt(w'));

    %The root prediction covariance.
    SPred=tria([xPropCenPoints, SQ]);
end

%LICENSE:
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
%OF RECIPIENT IN THE USE OF THE SOFTWARE.
