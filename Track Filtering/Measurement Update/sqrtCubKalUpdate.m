function [xUpdate, SUpdate, innov, Szz]=sqrtCubKalUpdate(xPred,SPred,z,SR,h,xi,w,innovTrans,measAvgFun,stateDiffTrans,stateTrans)
%SQRTCUBKALUPDATE Perform the measurement update step in the square root 
%                 cubature Kalman filter with additive measurement noise.
%
%INPUTS:    xPred           The xDim X 1 predicted target state.
%           SPred           The xDim X xDim lower-triangular predicted
%                           state covariance matrix.
%           z               The zDim X 1 vector measurement.
%           SR              The zDim X zDim lower-triangular square root of  
%                           the measurement covariance matrix in the native 
%                           coordiante system of the measurement.
%           h               A function handle for the measurement function
%                           that takes the state as its argument.
%           xi              An xDim X numCubPoints matrix of cubature
%                           points.
%           w               A numCubPoints X 1 vector of the weights 
%                           associated with the cubature points.
%          innovTrans       An optional function handle that transforms the
%                           value of the difference between the observation
%                           and any predicted points. This must be able to
%                           handle sets of differences. For a zDim
%                           measurement, this must be able to handle
%                           a zDimXN matrix of N differences. This only
%                           needs to be supplied when a measurement
%                           difference must to be restricted to a certain
%                           range. For example, the innovation between two
%                           angles will be 2*pi if one angle is zero and
%                           the other 2*pi, even though they are the same
%                           direction. In such an instance, a function
%                           handle to the wrapRange function with the
%                           appropriate parameters should be passed for
%                           innovTrans.
%           measAvgFun      An optional function handle that, when given N
%                           measurement values with weights, produces the
%                           weighted average. This function only has to be
%                           provided if the domain of the measurement is
%                           not linear. For example, when averaging angular
%                           values, then the function meanAng should be
%                           used.
%        stateDiffTrans     An optional function handle that, like
%                           innovTrans does for the measurements, takes an
%                           xDimXN matrix of N differences between states
%                           and transforms them however might be necessary.
%                           For example, a state containing angular
%                           components will generally need to be
%                           transformed so that the difference between the
%                           angles is wrapped to -pi/pi.
%             stateTrans    An optional function that takes a state
%                           estimate and transforms it. This is
%                           useful if one wishes the elements of the state
%                           to be bound to a certain domain. For example,
%                           if an element of the state is an angle, one
%                           might generally want to bind it to the region
%                           +/-pi.
%
%OUTPUTS    xUpdate     The xDim X 1 updated state vector.
%           SUpdate     The updated xDim X xDim lower-triangular square 
%                       root state covariance matrix.
%        innov, Szz     The zDimX1 innovation and the zDimXzDim square
%                       root innovation covariance matrix are returned in
%                       case one wishes to analyze the consistency of the
%                       estimator or use those values in gating or
%                       likelihood evaluation.
%
%If the function h needs additional parameters beyond the state, then the
%parameters can be passed by using an anonymous function as the function
%handle. For example, suppose that the measurement function is measFunc and
%it needs the additional parameters param1 and param2. In this instance,
%rather than using
%h=@measFunc
%one should use
%h=@(x)measFunc(x,param1,param2)
%This way, every time sqrtCubKalUpdate calls measFunc (via h) with a
%different x, those two parameters are always passed.
%
%The mathematics behind the function sqrtCubKalUpdate are described in more
%detail in Section IX of
%David F. Crouse , "Basic tracking using nonlinear 3D monostatic and
%bistatic measurements," IEEE Aerospace and Electronic Systems Magazine,
%vol. 29, no. 8, Part II, pp. 4-53, Aug. 2014.
%
%The optional parameters innovTrans and measAvgFun are not described in the
%above reference, but allow for possible modifications to the filter as
%described in
%D. F. Crouse, "Cubature/ unscented/ sigma point Kalman filtering with
%angular measurement models," in Proceedings of the 18th International
%Conference on Information Fusion, Washington, D.C., 6-9 Jul. 2015.
%The parameters have been added to allow the filter to be used with
%angular quantities. For example, if the measurement consisted of
%range and angle, z=[r;theta], then
%innovTrans=@(innov)[innov(1,:);
%                   wrapRange(innov(2,:),-pi,pi)];
%measAvgFun=@(z,w)[calcMixtureMoments(z(1,:),w);
%                  meanAng(z(2,:),w')];
%should be used to approximately deal with the circular nature of the
%measurements.
%
%July 2015 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

    if(nargin<8||isempty(innovTrans))
        %The function just returns the input.
        innovTrans=@(x)x;
    end
    
    if(nargin<9||isempty(measAvgFun))
       measAvgFun=@(zPoints,w)calcMixtureMoments(zPoints,w);
    end
    
    if(nargin<10||isempty(stateDiffTrans))
       stateDiffTrans=@(x)x; 
    end
    
    if(nargin<11)
       stateTrans=@(x)x; 
    end
    
    zDim=size(z,1);
    numCubPoints=size(xi,2);
    sqrtW=sqrt(w);
    %Calculate the updated estimates

    %Predicted cubature state points
    xPredPoints=stateTrans(transformCubPoints(xi,xPred,SPred));

    %Predicted, centered cubature state points
    xPredCenPoints=bsxfun(@times,stateDiffTrans(bsxfun(@minus,xPredPoints,xPred)),sqrtW');

    %Predicted cubature measurement points
    zPredPoints=zeros(zDim,numCubPoints);
    for curP=1:numCubPoints
        zPredPoints(:,curP)=h(xPredPoints(:,curP));
    end
    
    %Measurement prediction.
    zPred=measAvgFun(zPredPoints,w);
    
    %The innovation, transformed as necessary to keep values in a desired
    %range.
    innov=innovTrans(z-zPred);

    %Centered, predicted cubature measurement points, transformed as
    %necessary to keep the values within a desired range.
    zPredCenPoints=bsxfun(@times,innovTrans(bsxfun(@minus,zPredPoints,zPred)),sqrtW');

    %Root innovation covariance
    Szz=tria([zPredCenPoints,SR]);

    %The cross covariance.
    Pxz=xPredCenPoints*zPredCenPoints';

    %The filter gain
    W=(Pxz/Szz')/Szz;

    %Updated state estimate
    xUpdate=stateTrans(xPred+W*innov);
    
    %Updated state root covariance
    SUpdate=tria([stateDiffTrans(xPredCenPoints-W*zPredCenPoints),W*SR]);
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
