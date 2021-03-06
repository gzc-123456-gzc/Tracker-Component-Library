%-Abstract
%
%   CSPICE_OCCULT determines the occultation condition (not occulted,
%   partially, etc.) of one target relative to another target as seen
%   by an observer at a given time.
%
%-Disclaimer
%
%   THIS SOFTWARE AND ANY RELATED MATERIALS WERE CREATED BY THE
%   CALIFORNIA INSTITUTE OF TECHNOLOGY (CALTECH) UNDER A U.S.
%   GOVERNMENT CONTRACT WITH THE NATIONAL AERONAUTICS AND SPACE
%   ADMINISTRATION (NASA). THE SOFTWARE IS TECHNOLOGY AND SOFTWARE
%   PUBLICLY AVAILABLE UNDER U.S. EXPORT LAWS AND IS PROVIDED "AS-IS"
%   TO THE RECIPIENT WITHOUT WARRANTY OF ANY KIND, INCLUDING ANY
%   WARRANTIES OF PERFORMANCE OR MERCHANTABILITY OR FITNESS FOR A
%   PARTICULAR USE OR PURPOSE (AS SET FORTH IN UNITED STATES UCC
%   SECTIONS 2312-2313) OR FOR ANY PURPOSE WHATSOEVER, FOR THE
%   SOFTWARE AND RELATED MATERIALS, HOWEVER USED.
%
%   IN NO EVENT SHALL CALTECH, ITS JET PROPULSION LABORATORY, OR NASA
%   BE LIABLE FOR ANY DAMAGES AND/OR COSTS, INCLUDING, BUT NOT
%   LIMITED TO, INCIDENTAL OR CONSEQUENTIAL DAMAGES OF ANY KIND,
%   INCLUDING ECONOMIC DAMAGE OR INJURY TO PROPERTY AND LOST PROFITS,
%   REGARDLESS OF WHETHER CALTECH, JPL, OR NASA BE ADVISED, HAVE
%   REASON TO KNOW, OR, IN FACT, SHALL KNOW OF THE POSSIBILITY.
%
%   RECIPIENT BEARS ALL RISK RELATING TO QUALITY AND PERFORMANCE OF
%   THE SOFTWARE AND ANY RELATED MATERIALS, AND AGREES TO INDEMNIFY
%   CALTECH AND NASA FOR ALL THIRD-PARTY CLAIMS RESULTING FROM THE
%   ACTIONS OF RECIPIENT IN THE USE OF THE SOFTWARE.
%
%-I/O
%
%   Given:
%
%       target1   is the name of the first target body. Both object
%                 names and NAIF IDs are accepted. For example, both
%                 'Moon' and '301' are accepted.
%
%                 [1,a] = size(target1), char = class(target1)
%
%       shape1    is a string indicating the geometric model used to
%                 represent the shape of the first target body.
%
%                 [1,b] = size(shape1), char = class(shape1)
%
%                 The supported options are:
%
%                    'ELLIPSOID'     Use a triaxial ellipsoid model
%                                    with radius values provided via the
%                                    kernel pool. A kernel variable
%                                    having a name of the form
%
%                                       'BODYnnn_RADII'
%
%                                    where nnn represents the NAIF
%                                    integer code associated with the
%                                    body, must be present in the kernel
%                                    pool. This variable must be
%                                    associated with three numeric
%                                    values giving the lengths of the
%                                    ellipsoid's X, Y, and Z semi-axes.
%
%                    'POINT'         Treat the body as a single point.
%                                    When a point target is specified,
%                                    the occultation type must be
%                                    set to 'ANY'.
%
%                 At least one of the target bodies 'target1' or 'target2'
%                 must be modeled as an ellipsoid.
%
%                 Case and leading or trailing blanks are not
%                 significant in the string.
%
%       frame1    is the name of the body-fixed, body-centered reference
%                 frame associated with the first target body. Examples
%                 of such names are 'IAU_SATURN' (for Saturn) and
%                 'ITRF93' (for the Earth).
%
%                 [1,c] = size(frame1), char = class(frame1)
%
%                 If the first target body is modeled as a point, 'frame1'
%                 should be left blank (Ex: ' ').
%
%                 Case and leading or trailing blanks bracketing a
%                 non-blank frame name are not significant in the string.
%
%       target2   is the name of the second target body. See the description
%                 of 'target1' above for more details.
%
%                 [1,d] = size(target2), char = class(target2)
%
%       shape2    is the shape specification for the body designated
%                 by 'target2'. See the description of 'shape1' above for
%                 details.
%
%                 [1,e] = size(shape2), char = class(shape2)
%
%       frame2    is the name of the body-fixed, body-centered reference
%                 frame associated with the second target body. See the
%                 description of 'frame1' above for more details.
%
%                 [1,f] = size(frame2), char = class(frame2)
%
%       abcorr    indicates the aberration corrections to be applied to
%                 the state of each target body to account for one-way
%                 light time. Stellar aberration corrections are
%                 ignored if specified, since these corrections don't
%                 improve the accuracy of the occultation determination.
%
%                 [1,g] = size(abcorr), char = class(abcorr)
%
%                 See the header of the SPICE routine spkezr_c for a
%                 detailed description of the aberration correction
%                 options. For convenience, the options supported by
%                 this routine are listed below:
%
%                    'NONE'     Apply no correction.
%
%                    'LT'       "Reception" case: correct for
%                               one-way light time using a Newtonian
%                               formulation.
%
%                    'CN'       "Reception" case: converged
%                               Newtonian light time correction.
%
%                    'XLT'      "Transmission" case: correct for
%                               one-way light time using a Newtonian
%                               formulation.
%
%                    'XCN'      "Transmission" case: converged
%                               Newtonian light time correction.
%
%                 Case and blanks are not significant in the string
%                 'abcorr'.
%
%       observer  is the name of the body from which the occultation
%                 is observed. See the description of 'target1' for more
%                 details.
%
%                 [1,h] = size(observer), char = class(observer)
%
%       time      is the observation time in seconds past the J2000
%                 epoch.
%
%                 [1,n] = size(time), double = class(time)
%
%   the call:
%
%       occult_code = cspice_occult ( target1, shape1,   frame1, ...
%                                     target2, shape2,   frame2, ...
%                                     abcorr,  observer, time )
%
%   returns:
%
%       occult_code   is an integer occultation code indicating the geometric
%                     relationship of the three bodies.
%
%                     [1,n] = size(occult_code), double = class(occult_code)
%
%                     The meaning of the sign of 'occult_code' is given below.
%
%                        Code sign          Meaning
%                        ---------          ------------------------------
%                           > 0             The second ellipsoid is
%                                           partially or fully occulted
%                                           by the first.
%
%                           < 0             The first ellipsoid is
%                                           partially of fully
%                                           occulted by the second.
%
%                           = 0             No occultation.
%
%                     Possible 'occult_code' values and meanings are given
%                     below. The variable names indicate the type of
%                     occultation and which target is in the back. For example,
%                     MICE_OCCULT_TOTAL1_BACK represents a total occultation in
%                     which the first target is in the back (or occulted by)
%                     the second target. The variable names can be used in a
%                     program by calling 'MiceUser' as shown in the
%                     example program below.
%
%                        Name                    Code   Meaning
%                        ------                  -----  -----------------------
%                        MICE_OCCULT_TOTAL1_BACK  -3    Total occultation of
%                                                       first target by second.
%
%                        MICE_OCCULT_ANNLR1_BACK  -2    Annular occultation of
%                                                       first target by second.
%                                                       The second target does
%                                                       not block the limb of
%                                                       the first.
%
%                        MICE_OCCULT_PARTL1_BACK  -1    Partial occultation of
%                                                       first target by second
%                                                       target.
%
%                        MICE_OCCULT_NOOCC         0    No occultation or
%                                                       transit: both objects
%                                                       are completely visible
%                                                       to the observer.
%
%                        MICE_OCCULT_PARTL2_BACK   1    Partial occultation of
%                                                       second target by first
%                                                       target.
%
%                        MICE_OCCULT_ANNLR2_BACK   2    Annular occultation of
%                                                       second target by first.
%
%                        MICE_OCCULT_TOTAL2_BACK   3    Total occultation of
%                                                       second target by first.
%
%-Examples
%
%   Any numerical results shown for this example may differ between
%   platforms as the results depend on the SPICE kernels used as input
%   and the machine specific arithmetic implementation.
%
%   Example(1):
%
%      Find whether MRO is occulted by Mars as seen by
%      the DSS-13 ground station at a few specific
%      times.
%
%         KPL/MK
%
%         File: mro_ex_occult.tm
%
%         This is the meta-kernel file for the example problem for
%         the subroutine occult_c. These kernel files can be found in
%         the NAIF archives.
%
%         In order for an application to use this meta-kernel, the
%         kernels referenced here must be present in the user's
%         current working directory.
%
%         The names and contents of the kernels referenced
%         by this meta-kernel are as follows:
%
%               File name                       Contents
%               ---------                       --------
%               de421.bsp                       Planetary ephemeris
%               earthstns_itrf93_050714.bsp     DSN station ephemeris
%               pck00010.tpc                    Planet orientation and
%                                               radii
%               earth_000101_120409_120117.bpc  High precision Earth
%                                               orientation
%               mro_psp_rec.bsp                 MRO ephemeris
%               naif0010.tls                    Leapseconds
%               earth_topo_050714.tf            Topocentric reference
%                                               frames for
%                                               DSN stations
%
%         \begindata
%
%         KERNELS_TO_LOAD = ( 'de421.bsp',
%                             'earthstns_itrf93_050714.bsp',
%                             'pck00010.tpc',
%                             'earth_000101_120409_120117.bpc',
%                             'mro_psp_rec.bsp',
%                             'naif0010.tls',
%                             'earth_topo_050714.tf' )
%         \begintext
%
%         End of meta-kernel
%
%      Example program starts here.
%
%         %
%         %   MiceUser is a file that makes occultation-specific
%         %   variables global. You must call MiceUser to have access to
%         %   these variable names. These variables are defined so you don't
%         %   need to remember what the integer codes mean that the
%         %   occultation routine returns. For more information, please see
%         %   MiceUser.m and MiceOccult.m.
%         %
%         MiceUser;
%
%         target1  = 'MRO';
%         shape1   = 'point';
%         target2  = 'Mars';
%         shape2   = 'ellipsoid';
%         observer = 'DSS-13';
%         dt = 1000;
%         out_form = '%s %s %s %s wrt %s\n';
%         out_char = ['totally occulted by  ';
%                     'transited by         ';
%                     'partially occulted by';
%                     'not occulted by      '];
%
%         %
%         %   Load the meta kernel.
%         %
%         cspice_furnsh ( 'mro_ex_occult.tm' );
%
%         et_start = cspice_str2et ( '2012-jan-5 1:15:00 UTC' );
%         et_stop  = cspice_str2et ( '2012-jan-5 2:50:00 UTC' );
%
%         for et = et_start : dt : et_stop
%
%             %
%             %   Calculate the type of occultation that
%             %   corresponds to time ET.
%             %
%             occult_code = cspice_occult ( target1, shape1, ' ', ...
%                                           target2, shape2, 'iau_mars', ...
%                                           'cn', observer, et );
%             %
%             %   Output the results.
%             %
%             time = cspice_timout ( et, 'YYYY-MM-DD HR:MN ::UTC-8');
%
%             %
%             %   Remember: You must call 'MiceUser' before
%             %   using the parameters like 'MICE_OCCULT_TOTAL1_BACK' in
%             %   the case statements below.
%             %
%             switch occult_code
%                 case MICE_OCCULT_TOTAL1_BACK
%                     fprintf (out_form, time, target1, out_char(1,:), ...
%                              target2,  observer )
%                 case MICE_OCCULT_ANNLR1_BACK
%                     fprintf (out_form, time, target1, out_char(2,:), ...
%                              target2,  observer )
%                 case MICE_OCCULT_PARTL1_BACK
%                     fprintf (out_form, time, target1, out_char(3,:), ...
%                              target2,  observer )
%                 case MICE_OCCULT_NOOCC
%                     fprintf (out_form, time, target1, out_char(4,:), ...
%                              target2,  observer )
%                 case MICE_OCCULT_PARTL2_BACK
%                     fprintf (out_form, time, target2, out_char(3,:), ...
%                              target1,  observer )
%                 case MICE_OCCULT_ANNLR2_BACK
%                     fprintf (out_form, time, target2, out_char(2,:), ...
%                              target1,  observer )
%                 case MICE_OCCULT_TOTAL2_BACK
%                     fprintf (out_form, time, target2, out_char(1,:), ...
%                              target1,  observer )
%                 otherwise
%                     fprintf ( 'Bad occultation code: %d\n', occult_code )
%             end
%
%         end
%
%         %
%         %   Unload kernels
%         %
%         cspice_kclear
%
%   MATLAB outputs:
%
%         2012-01-04 17:15 Mars transited by          MRO wrt DSS-13
%         2012-01-04 17:31 MRO not occulted by       Mars wrt DSS-13
%         2012-01-04 17:48 MRO totally occulted by   Mars wrt DSS-13
%         2012-01-04 18:04 MRO totally occulted by   Mars wrt DSS-13
%         2012-01-04 18:21 MRO not occulted by       Mars wrt DSS-13
%         2012-01-04 18:38 Mars transited by          MRO wrt DSS-13
%
%-Particulars
%
%   For many purposes, modeling extended bodies as triaxial
%   ellipsoids is adequate for determining whether one body is
%   occulted by another as seen from a specified observer.
%
%-Required Reading
%
%   For important details concerning this module's function, please refer to
%   the CSPICE routine occult_c.
%
%-Version
%
%   -Mice Version 1.0.0, 14-NOV-2013, SCK (JPL)
%
%-Index_Entries
%
%   occultation type at a specified time
%
%-&

function occult_code = cspice_occult ( target1, shape1,   frame1, ...
                                       target2, shape2,   frame2, ...
                                       abcorr,  observer, time )

   switch nargin
      case 9

         target1  = zzmice_str(target1);
         shape1   = zzmice_str(shape1);
         frame1   = zzmice_str(frame1);
         target2  = zzmice_str(target2);
         shape2   = zzmice_str(shape2);
         frame2   = zzmice_str(frame2);
         abcorr   = zzmice_str(abcorr);
         observer = zzmice_str(observer);
         time     = zzmice_dp(time);

      otherwise

         error ( ['Usage: [_output_state_] = ' ...
                  'cspice_occult( `target1`, `shape1`, `frame1`,' ...
                  '`target2`, `shape2`, `frame2`, `abcorr`, '...
                  '`observer`, _time_)'] )

   end

   %
   % Call the MEX library. An "_s" suffix indicates a structure type
   % return argument (not present in this case).
   %
   try
      [occult_code] = mice('occult_c', target1, shape1,   frame1, ...
                                       target2, shape2,   frame2, ...
                                       abcorr,  observer, time );

   catch
      rethrow(lasterror)
   end







