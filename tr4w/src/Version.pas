// This file is part of TR4W  (SRC)
{
 TR4W is free software: you can redistribute it and/or
 modify it under the terms of the GNU General Public License as
 published by the Free Software Foundation, either version 2 of the
 License, or (at your option) any later version.

 TR4W is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General
     Public License along with TR4W in  GPL_License.TXT.
If not, ref:
http://www.gnu.org/licenses/gpl-3.0.txt
 }
unit version;
interface


const


<<<<<<< HEAD
 TR4W_CURRENTVERSION_NUMBER            = '4.115.1' ;  // N4af     New Release



=======
 TR4W_CURRENTVERSION_NUMBER            = '4.114.1' ;  // N4af     New Release
>>>>>>> 409c166c804feb7fcc388df512c45c35e05f191e



  TR4W_CURRENTVERSION                   = 'TR4W v.' + TR4W_CURRENTVERSION_NUMBER; //  {$IF MMTTYMODE} + '_mmtty'{$IFEND};//{$IF LANG <> 'ENG'} + ' [' + LANG + ']'{$IFEND}{$IF MMTTYMODE} + '_mmtty'{$IFEND};
<<<<<<< HEAD
  TR4W_CURRENTVERSIONDATE               = 'September, 2022' ;
=======
  TR4W_CURRENTVERSIONDATE               = 'August, 2022' ;
>>>>>>> 409c166c804feb7fcc388df512c45c35e05f191e

  TR4WSERVER_CURRENTVERSION             = '1.41';

 implementation

 end.

