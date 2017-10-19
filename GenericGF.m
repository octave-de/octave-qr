##
## Copyright 2008 ZXing authors
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##      http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##

## author Sean Owen
## author David Olivier

## This class contains utility methods for performing mathematical operations
## over the Galois Fields.  Operations use a given primitive polynomial in
## calculations.
##
## Throughout this package, elements of the GF are represented as an uint32
## for convenience and speed (but at the cost of memory).

classdef GenericGF < handle

  ## QR_CODE_FIELD_256 is the only instance
  properties
    expTable;
    logTable;
    zero;
    ## The size of the field.
    size = 256;
    ## Irreducible polynomial whose coefficients are represented by the bits of
    ## an int, where the least-significant bit represents the constant
    ## coefficient
    primitive = uint32 (0x011D); # x^8 + x^4 + x^3 + x^2 + 1
    ## The generator polynomial can be 0- or 1-based
    ##   g(x) = (x+a^b)(x+a^(b+1))...(x+a^(b+2t-1)).
    ## In most cases it should be 1, but for QR code it is 0.
    generatorBase = 0;
  endproperties

  methods
    function obj = GenericGF ()
      obj.expTable = uint32 (zeros (1, obj.size));
      obj.logTable = uint32 (zeros (1, obj.size));
      x = uint32 (1);
      for i = 1:obj.size
        obj.expTable(i) = x;
        x *= 2; # we're assuming the generator alpha is 2
        if (x >= obj.size)
          x = bitxor (x, obj.primitive);
          x = bitand (x, obj.size - 1);
        endif
      endfor
      for i = 1:(obj.size - 1)
        obj.logTable(obj.expTable(i) + 1) = i - 1;
      endfor
      ## logTable[0] == 0 but this should never be used
      zero = GenericGFPoly(obj, [0]);
    endfunction

    function z = getZero (obj)
      z = obj.zero;
    endfunction

    ## Return the monomial representing coefficient * x^degree.
    function ret = buildMonomial(obj, degree, coefficient)
      if (degree < 0)
        error ("GenericGF: degree may not be negative.");
      endif
      if (coefficient == 0)
        ret = obj.zero;
        return;
      endif
      coefficients = [coefficient, zeros(1, degree)];
      ret = GenericGFPoly(obj, coefficients);
    endfunction

    ## FIXME: replace by bitxor (a, b)
    ## int addOrSubtract(int a, int b)

    ## Return 2 to the power of a in GF(size).
    function ret = exp (obj, a)
      ret = obj.expTable(a);
    endfunction

    ## Return base 2 log of a in GF(size).
    function ret = log (obj, a)
      ret = obj.logTable(a);
    endfunction

    ## Return multiplicative inverse of a
    function ret = inverse (obj, a)
      ret = obj.expTable(obj.size - obj.logTable(a) - 1);
    endfunction

    ## Return product of a and b in GF(size)
    function ret = multiply (obj, a, b)
      if (a == 0 || b == 0)
        ret = 0;
      endif
      ret = obj.expTable(mod ((obj.logTable(a + 1) + obj.logTable(b + 1)),
                              (obj.size - 1)) + 1);
    endfunction

    function ret = getSize (obj)
      ret = obj.size;
    endfunction

    function ret = getGeneratorBase (obj)
      ret = obj.generatorBase;
    endfunction

    function display (obj)
      fprintf("GF(0x%s, %d)\n", dec2hex (obj.primitive), obj.size);
    endfunction

  endmethods

endclassdef

%!test
%! a = GenericGF ();
%! eT = uint32 ([ ...
%!   1, 2, 4, 8, 16, 32, 64, 128, 29, 58, 116, 232, 205, 135, 19, 38, 76, ...
%! 152, 45, 90, 180, 117, 234, 201, 143, 3, 6, 12, 24, 48, 96, 192, ...
%! 157, 39, 78, 156, 37, 74, 148, 53, 106, 212, 181, 119,238, 193, 159, ...
%!  35, 70, 140, 5, 10, 20, 40, 80, 160, 93, 186, 105, 210, 185, 111, ...
%! 222, 161, 95, 190, 97, 194, 153, 47, 94, 188, 101, 202, 137, 15, 30, ...
%!  60, 120, 240, 253, 231, 211, 187, 107, 214, 177, 127, 254, 225, 223, ...
%! 163, 91, 182, 113, 226, 217, 175, 67, 134, 17, 34, 68, 136, 13, 26, ...
%!  52, 104, 208, 189, 103, 206, 129, 31, 62, 124, 248, 237, 199, 147, ...
%!  59, 118, 236, 197, 151, 51, 102, 204, 133, 23, 46, 92, 184, 109, 218, ...
%! 169, 79, 158, 33, 66, 132, 21, 42, 84, 168, 77, 154, 41, 82, 164, 85, ...
%! 170, 73, 146, 57, 114, 228, 213, 183, 115, 230, 209, 191, 99, 198, ...
%! 145, 63, 126, 252, 229, 215, 179, 123, 246, 241, 255, 227, 219, 171, ...
%!  75, 150, 49, 98, 196, 149, 55, 110, 220, 165, 87, 174, 65, 130, 25, ...
%!  50, 100, 200, 141, 7, 14, 28, 56, 112, 224, 221, 167, 83, 166, 81, ...
%! 162, 89, 178, 121, 242, 249, 239, 195, 155, 43, 86, 172, 69, 138, 9, ...
%!  18, 36, 72, 144, 61, 122, 244, 245, 247, 243, 251, 235, 203, 139, 11, ...
%!  22, 44, 88, 176, 125, 250, 233, 207, 131, 27, 54, 108, 216, 173, 71, ...
%! 142, 1]);
%!
%! lT = uint32 ([ ...
%!   0, 0, 1, 25, 2, 50, 26, 198, 3, 223, 51, 238, 27, 104, 199, 75, 4, 100, ...
%! 224, 14, 52, 141,239, 129, 28, 193, 105, 248, 200, 8, 76, 113, 5, 138, ...
%! 101, 47, 225, 36, 15, 33, 53, 147, 142, 218,240, 18, 130, 69, 29, 181, ...
%! 194, 125, 106, 39, 249, 185, 201, 154, 9, 120, 77, 228, 114, 166, 6, 191, ...
%! 139, 98, 102, 221, 48, 253, 226, 152, 37, 179, 16, 145, 34, 136, 54, 208, ...
%! 148, 206, 143, 150, 219, 189, 241, 210, 19, 92, 131, 56, 70, 64, 30, 66, ...
%! 182, 163, 195, 72, 126, 110, 107, 58, 40, 84, 250, 133, 186, 61, 202, 94, ...
%! 155, 159, 10, 21, 121, 43, 78, 212, 229, 172, 115, 243, 167, 87, 7, 112, ...
%! 192, 247, 140, 128, 99, 13, 103, 74, 222, 237, 49, 197, 254, 24, 227, ...
%! 165, 153, 119, 38, 184, 180, 124, 17, 68, 146, 217, 35, 32, 137, 46, 55, ...
%!  63, 209, 91, 149, 188, 207, 205, 144, 135, 151, 178, 220, 252, 190, 97, ...
%! 242, 86, 211, 171, 20, 42, 93, 158, 132, 60, 57, 83, 71, 109, 65, 162, ...
%!  31, 45, 67,216, 183, 123, 164, 118, 196, 23, 73, 236, 127, 12, 111, 246, ...
%! 108, 161, 59, 82, 41, 157, 85, 170, 251, 96, 134, 177, 187, 204, 62, 90, ...
%! 203, 89, 95, 176, 156, 169, 160, 81, 11, 245, 22, 235, 122, 117, 44, 215, ...
%!  79, 174, 213, 233, 230, 231, 173, 232, 116, 214, 244, 234, 168, 80, 88, ...
%! 175]);
%! assert (a.expTable, eT)
%! assert (a.logTable, lT)
