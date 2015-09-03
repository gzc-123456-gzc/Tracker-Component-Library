function [C,S,a,c]=getWMMCoeffs(year,fullyNormalize)
%%GETWMMCOEFFS Obtain spherical harmonic coefficients for the 2015 
%              version of the DoD's World Magnetic Model (WMM) at a
%              particular time or at the reference epoch (2015). The WMM
%              predicts the Earth's core field forward in time from the
%              reference epoch. Past field data, the International
%              geomagnetic Reference Field (IGRF) is suggested. If a
%              high precision prediction of a field reading at a point on
%              the surface of the Earth is desired, then a crustal field is
%              also necessary. In such an instance, the Enhanced Magnetic
%              Model (EMM), which is a combined crustal and core field
%              model, shoud be used instead. The WMM model is valid
%              for altitudes from 1km underground to 850km above
%              ground.
%
%INPUTS: year        A decimal number indicating a year in the Gregorian
%                    calendar as specified by universal coordinated time
%                    (UTC). For example, halfway through the year 2017
%                    would be represented as 2017.5. The precision of the
%                    model is not sufficiently fine that leap seconds
%                    matter. If this parameter is omitted, then the
%                    reference year of 2015 is used. Years from 2015 onward
%                    should be uased as past years are better modeled using
%                    the IGRF.
%    fullyNormalize  Geomagnetic models are normally given in terms of
%                    Schmidt semi-normalized Legendre functions. If
%                    fullyNormalize =true, then the coefficients are
%                    converted for use with fully normalized associated
%                    Legendre functions, as are commonly used with
%                    spherical harmonic algorithms for gravitational
%                    models. If this parameter is omitted, the default
%                    value is true.
%
%OUTPUTS: C     A ClusterSet class holding the coefficient terms that are
%               multiplied by cosines in the harmonic expansion. C(n+1,m+1)
%               is the coefficient of degree n and order m. The
%               coefficients have units of Tesla. The coefficients are
%               normalized according to the fullyNormalize term.
%         S     A ClusterSet class holding the coefficient terms that are
%               multiplied by sines in the harmonic expansion. The
%               format of S is the same as that of C.
%         a     The numerator in the (a/r)^n term in the spherical harmonic
%               sum having units of meters.
%         c     The constant value by which the spherical harmonic series
%               is multiplied, having units of squared meters.
%
%Details on the normalization of the coefficients is given in the comments
%to the function spherHarmonicEval.
%
%Documentation for the WMM is given in
%S. Maus, S. McLean, M. Nair, and C. Rollins, "The US/UK
%world magnetic model for 2010-2015," National Oceanographic and
%Atmospheric Organization, Tech. Rep. NESDIS/NGDC, 2010. [Online].
%Available: http://www.ngdc.noaa.gov/geomag/WMM/
%and information on Schmidt semi-normalized Legendre functions is given in
%D. E. Winch, D. J. Ivers, J. P. R. Turner, and R. J. Stening,
%"Geomagnetism and Schmidt quasi-normalization," Geophysical Journal
%International, vol. 160, no. 2, pp. 487-504, Feb. 2005.
%
%January 2015 David F. Crouse, Naval Research Laboratory, Washington D.C.
%(UNCLASSIFIED) DISTRIBUTION STATEMENT A. Approved for public release.

%Read the WMM data file, which should be located in a data folder that is
%in the same folder as this file.
ScriptPath=mfilename('fullpath');
ScriptFolder = fileparts(ScriptPath);

fileID=fopen([ScriptFolder,'/data/WMM.COF']);
data=textscan(fileID,'%s','CommentStyle','#','whitespace',' ','delimiter','\n');
fclose(fileID);
data=data{1};
%data{1} is just a bunch of labels that can be ignored. The last two rows
%in data are just a bunch of 9's and can also be ignored.

%Put all of the elements for each row into a cell array.
numRows=length(data)-3;
rowData=cell(numRows,1);
for curRow=1:numRows
    V=textscan(data{curRow+1},'%f %f %f %f %f %f','whitespace',' ');
    rowData{curRow}=V;
end

%The reference year
yearRef=2015.0;
M=12;%The maximum degree and order of the model.

%Allocate space for two sets of coefficients. these are needed so that
%interpolation between the years can be performed, if necessary.
totalNumCoeffs=(M+1)*(M+2)/2;
emptyData=zeros(totalNumCoeffs,1);
clustSizes=1:(M+1);
C=ClusterSet(emptyData,clustSizes);
S=ClusterSet(emptyData,clustSizes);
C1=ClusterSet(emptyData,clustSizes);
S1=ClusterSet(emptyData,clustSizes);

%The closest two years of coefficients for the data must be extracted from
%rowData in so that one can linearly interpolate the coefficients to the
%proper time. If the time requested falls after the final year, then the SV
%values must be taken from rowData for future interpolation. If no date is
%given, then the final reference date in the model is used and no
%interpolation is performed.

if(nargin==0)
    year=yearRef;
end

if(nargin<2)
   fullyNormalize=true; 
end

if(year~=yearRef)
    if(year<yearRef)
        warning('Interpolation to past years might not be accurate');
    end
    
    putCoeffsIntoC(rowData,C,3);
    putCoeffsIntoC(rowData,S,4);
    %The slopes for interpolation.
    putCoeffsIntoC(rowData,C1,5);
    putCoeffsIntoC(rowData,S1,6);
    
    yearDiff=year-yearRef;
    
    %Perform linear interpolation.
    for n=0:M
        for m=0:n
            C(n+1,m+1)=C(n+1,m+1)+yearDiff*C1(n+1,m+1);
            S(n+1,m+1)=S(n+1,m+1)+yearDiff*S1(n+1,m+1);
        end
    end
else
    putCoeffsIntoC(rowData,C,3);
    putCoeffsIntoC(rowData,S,4);
end

%Change the units from Nanotesla to Tesla.
C(:)=10^(-9)*C(:);
S(:)=10^(-9)*S(:);

%If the coefficients should be fully normalized.
if(fullyNormalize~=false)
     for n=0:M
        k=1/sqrt(1+2*n);
        C(n+1,:)=k*C(n+1,:);
        S(n+1,:)=k*S(n+1,:);
     end
end

a=Constants.WMM2010SphereRad;%meters
c=a^2;
end

function putCoeffsIntoC(rowData,C,idx)
    %Put the data from column idx for all rows of rowData into the S and C
    %matrices.
    numRows=length(rowData);
    
    for curRow=1:numRows
        %Extract the order and degree.
        n=rowData{curRow}{1};
        m=rowData{curRow}{2};
        
        %Extract the coefficient in the column given by idx.
        C(n+1,m+1)=rowData{curRow}{idx};
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
