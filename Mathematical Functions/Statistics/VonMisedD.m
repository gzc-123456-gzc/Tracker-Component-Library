classdef VonMisedD
%Functions to handle the von Mises distribution, which is a common circular
%distribution.
%Implemented methods are: PDF, trigMoment, rand
%
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

methods(Static)

function val=PDF(x,kappa,mu)
%%PDF  Evaluate a von Mises PDF at a given point with the specified
%      parameters.
%
%INPUTS: x      The point(s) at which the von Mises distribution is to be
%               evaluated.
%        kappa  The concentration of the distribution 0<=kappa<inf.
%        mu     The mean direction of the distribution. This is normally
%               between -pi and pi.
%
%OUTPUTS:   val The value(s) of the von Mises PDF with the specified
%               parameters evaluated at x.
%
%The von Mises distribution is used to model errors on angular quantities.
%It is described in
%N. Fisher, Statistical Analysis of Circular Data. Cambridge, UK:
%Cambridge University Press, 1993.
%and
%K. V. Mardia and P. E. Jupp, Directional Statistics. Chichester, England:
%John Wiley & Sons, 2000.
%
%October 2013 David F. Crouse, Naval Research Laboratory, Washington D.C.

    val=exp(kappa*cos(x-mu))/(2*pi*besseli(0,kappa));
end

function [theta, R, rho]=trigMoment(n,kappa,mu)
%%TRIGMOMENT Compute the nth trigonometric moment of a von Mises
%            distribution having the given parameters. A direction theta on
%            the unit circle canbe modeled as a complex quantity having
%            unit magnitude as exp(1j*theta). The raw complex trigonometric
%            moment is thus the expected value of exp(1j*n*theta), where
%            the integral for the expected value is taken over any interval
%            of length 2*pi.
%
%INPUTS: n The order of the moment desired. This is >=1.
%    kappa The concentration of the distribution 0<=kappa<inf. For
%          kappa>500, the results might be inaccurate.
%       mu The mean direction of the distribution. This is normally between
%          -pi and pi.
%
%OUTPUTS: theta The (real) trigonometric mean angle in radians for the nth
%               moment. This is between -pi and pi.
%             R The (real) mean resultant length for the nth moment.
%           rho The (complex) mean resultant value for the nth moment. Note
%               that rho=R*exp(1j*theta).
%
%The moments of a von Mises distribution are given in Chapter 2.2.4 of
%S. R. Jammalamadaka and A. SenGupta, Topics in Circular Statistics.
%Singapore: World Scientific, 2001.
%
%August 2015 David F. Crouse, Naval Research Laboratory, Washington D.C.

%For n=1 or 2, there should be no need to use anything but the default
%maximum number of iterations in BesseliRatio.
if(n==1)
    rho=BesseliRatio(1,kappa)*exp(1j*n*mu);
elseif(n==2)
    rho=BesseliRatio(2,kappa)*BesseliRatio(1,kappa)*exp(1j*n*mu);
else
    rho=besseli(n,kappa,1)/besseli(0,kappa,1)*exp(1j*n*mu);
end

theta=angle(rho);
R=abs(rho);
end

function vals=rand(N,kappa,mu)
%%RAND Generate von Mises random variables with the given parameters.
%
%INPUTS:    N   If N is a scalar, then randRayleigh returns an NXN matrix
%               of random variables. If N=[M,N1] is a two-element row
%               vector, then randRayleigh returns an MXN1 matrix of random
%               variables.
%        kappa  The concentration of the distribution 0<=kappa<inf.
%        mu     The mean direction of the distribution. This is normally
%               between -pi and pi.
%
%OUTPUTS:   vals   A matrix whose dimensions are determined by N of the
%                  generated von Mises random variables.
%
%The algorithm if that of Section 4 of [1], which is a rejection sampling
%method based on using a wrapped Cauchy distribution as a proposal density.
%However, the range of the random variable u1 in [1] does not appear to be
%correct. The correct formulation is based on Chapter 7.3 of [2] using the
%errata available at http://luc.devroye.org/errors.pdf   so u1 is randomly
%generated between -1 and 1 as opposed to between 0 and 1.
%
%[1] D. J. Best and N. I. Fisher, "Efficient simulation of the von Mises
%    distribution," Journal of the Royal Statistical Society. Seriec C
%    (Applied Statistics), vol. 28, no. 2, pp. 152?157, 1979.
%[2] L. Devroye, Non-Uniform random Variate Generation. New York:
%    Springer-Verlag, 1986.
%
%August 2015 David F. Crouse, Naval Research Laboratory, Washington D.C.

    if(isscalar(N))
        dims=[N N];
    else
        dims=N;
    end

    vals=zeros(dims);%Allocate space
    numSamp=prod(dims);

    %Step 0
    tau=1+sqrt(1+4*kappa^2);
    rho=(tau-sqrt(2*tau))/(2*kappa);
    r=(1+rho^2)/(2*rho);
    
    for curSamp=1:numSamp
        while(1)
            %Step 1
            u1=2*rand(1)-1;%In range [-1,1]
            z=cos(pi*u1);
            f=(1+r*z)/(r+z);
            c=kappa*(r-f);

            %Step 2
            u2=rand(1);%in range [0,1]
            if(c*(2-c)-u2>0)
               break;
            end

            %Step 3
            if(log(c/u2)+1-c>=0)
                break;
            end
        end
        %Step 4
        u3=2*rand(1)-1;%In range [-1,1]
        vals(curSamp)=wrapRange(sign(u3)*acos(f)+mu,-pi,pi);
    end
end
    
end
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
