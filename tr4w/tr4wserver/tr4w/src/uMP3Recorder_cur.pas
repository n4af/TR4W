unit uMP3Recorder;

interface
uses
//  spectrum_vis,
  LogK1EA,
  TF,
  VC,
  LogWind,
  PostUnit,
  LogDupe,
  MMSystem,
  Windows,
  Tree,
  Messages
  ;
type
  TMP3RecorderDuration = (rdEachQSO, rdEachHour, rdNonStop);
  {(*}
  TID3Rec = packed record
    Tag     : array[0..2] of Char;
    Title   : array[0..29] of Char;
    Artist  : array[0..29] of Char;
    Album   : array[0..29] of Char;
    Year    : array[0..3] of Char;
    comment : array[0..29] of Char;
    Genre   : Byte;
  end;
{*)}
type
  THBE_STREAM = longword;
  PHBE_STREAM = ^PHBE_STREAM;
  BE_ERR = longword;
const

// List of valid bitrates[kbps]& sample frequencies[hz].
// first Index
// 0 : MPEG - 2 values(sample frequencies 16...24 kHz)
// 1 : MPEG - 1 values(sample frequencies 32...48 kHz)
// 2 : MPEG - 2.5 values(sample frequencies 8...12 kHz)
  MPEG1                                 = 1;
  MPEG2                                 = 0;
  MPEG25                                = 2;

   // encoding formats
  BE_CONFIG_MP3                         = 0;
  BE_CONFIG_LAME                        = 256;

  LQP_NOPRESET                          = -1;

   // QUALITY PRESETS
  LQP_NORMAL_QUALITY                    = 0;
  LQP_LOW_QUALITY                       = 1;
  LQP_HIGH_QUALITY                      = 2;
  LQP_VOICE_QUALITY                     = 3;
  LQP_R3MIX                             = 4;
  LQP_VERYHIGH_QUALITY                  = 5;
  LQP_STANDARD                          = 6;
  LQP_FAST_STANDARD                     = 7;
  LQP_EXTREME                           = 8;
  LQP_FAST_EXTREME                      = 9;
  LQP_INSANE                            = 10;
  LQP_ABR                               = 11;
  LQP_CBR                               = 12;
  LQP_MEDIUM                            = 13;
  LQP_FAST_MEDIUM                       = 14;
   // NEW PRESET VALUES
  LQP_PHONE                             = 1000;
  LQP_SW                                = 2000;
  LQP_AM                                = 3000;
  LQP_FM                                = 4000;
  LQP_VOICE                             = 5000;
  LQP_RADIO                             = 6000;
  LQP_TAPE                              = 7000;
  LQP_HIFI                              = 8000;
  LQP_CD                                = 9000;
  LQP_STUDIO                            = 10000;

  BE_ERR_SUCCESSFUL                     : longword = 0;
  BE_ERR_INVALID_FORMAT                 : longword = 1;
  BE_ERR_INVALID_FORMAT_PARAMETERS      : longword = 2;
  BE_ERR_NO_MORE_HANDLES                : longword = 3;
  BE_ERR_INVALID_HANDLE                 : longword = 4;
   // other constants
  BE_MAX_HOMEPAGE                       = 256;
   // format specific variables

  BE_MP3_MODE_STEREO                    = 0;
  BE_MP3_MODE_JSTEREO                   = 1;
  BE_MP3_MODE_DUALCHANNEL               = 2;
  BE_MP3_MODE_MONO                      = 3;

const
  VBR_METHOD_NONE                       = -1;
  VBR_METHOD_DEFAULT                    = 0;
  VBR_METHOD_OLD                        = 1;
  VBR_METHOD_NEW                        = 2;
  VBR_METHOD_MTRH                       = 3;
  VBR_METHOD_ABR                        = 4;
type
  MCI_DGV_OPEN_PARMS = record
    dwCallback: PDWORD;
    wDeviceID: UINT;
    lpstrDeviceType: LPTSTR;
    lpstrElementName: LPTSTR;
    lpstrAlias: LPTSTR;
    dwStyle: DWORD;
    hwndParent: HWND;
  end;

const

  MCI_DGV_OPEN_WS                       = $00010000;
  MCI_DGV_OPEN_PARENT                   = $00020000;
  MCI_DGV_OPEN_NOSTATIC                 = $00040000;
  MCI_DGV_OPEN_16BIT                    = $00080000;
  MCI_DGV_OPEN_32BIT                    = $00100000;

type
  TMP3 = packed record
    dwSampleRate: DWORD;
    byMode: Byte;
    wBitRate: Word;
    bPrivate: BOOL;
    bCRC: BOOL;
    bCopyright: BOOL;
    bOriginal: BOOL;
  end;

  TLHV1 = packed record

    dwStructVersion: DWORD;
    dwStructSize: DWORD;

    dwSampleRate: DWORD; // SAMPLERATE OF INPUT FILE
    dwReSampleRate: DWORD; // DOWNSAMPLERATE, 0=ENCODER DECIDES
    nMode: longword; // BE_MP3_MODE_STEREO, BE_MP3_MODE_DUALCHANNEL, BE_MP3_MODE_MONO
    dwBitrate: DWORD; // CBR bitrate, VBR min bitrate
    dwMaxBitrate: DWORD; // CBR ignored, VBR Max bitrate
    nPreset: longword; // Quality preset, use one of the settings of the LAME_QUALITY_PRESET enum
    dwMpegVersion: DWORD; // FUTURE USE, MPEG-1 OR MPEG-2
    dwPsyModel: DWORD; // FUTURE USE, SET TO 0
    dwEmphasis: DWORD; // FUTURE USE, SET TO 0
      // BIT STREAM SETTINGS
    bPrivate: boolean; // Set Private Bit (TRUE/FALSE)
    bCRC: boolean; // Insert CRC (TRUE/FALSE)
    bCopyright: boolean; // Set Copyright Bit (TRUE/FALSE)
    bOriginal: boolean; // Set Original Bit (TRUE/FALSE)
      // VBR STUFF
    bWriteVBRHeader: boolean; // WRITE XING VBR HEADER (TRUE/FALSE)
    bEnableVBR: boolean; // USE VBR ENCODING (TRUE/FALSE)
    nVBRQuality: integer; // VBR QUALITY 0..9
    dwVbrAbr_bps: DWORD; // Use ABR in stead of nVBRQuality
    nVbrMethod: SHORTINT;
    bNoRes: boolean; // Disable Bit resorvoir (TRUE/FALSE)
      // MISC SETTINGS
    bStrictIso: boolean; // Use strict ISO encoding rules (TRUE/FALSE)
    nQuality: Word; // Quality Setting, HIGH BYTE should be NOT LOW byte, otherwhise quality=5
      // FUTURE USE, SET TO 0, align strucutre to 331 bytes
    btReserved: array[0..263] of Byte;

  end;

  TAAC = packed record
    dwSampleRate: DWORD;
    byMode: Byte;
    wBitRate: Word;
    byEncodingMethod: Byte;
  end;

  TFormat = packed record
    case Byte of
      1: (mp3: TMP3);
      2: (lhv1: TLHV1);
      3: (aac: TAAC);
  end;

  TBE_Config = packed record
    dwConfig: longword;
    Format: TFormat;
  end;

  PBE_Config = ^TBE_Config;

  TBE_Version = record
    byDLLMajorVersion: Byte;
    byDLLMinorVersion: Byte;
    byMajorVersion: Byte;
    byMinorVersion: Byte;
    byDay: Byte;
    byMonth: Byte;
    wYear: Word;
    zHomePage: array[0..BE_MAX_HOMEPAGE + 1] of Char;
  end;
  PBE_Version = ^TBE_Version;

type
  TbeInitStream = function(var pbeConfig: TBE_CONFIG; var dwSample: longword; var dwBufferSize: longword; var phbeStream: THBE_STREAM): BE_Err; cdecl;
  TbeEncodeChunk = function(hbeStream: THBE_STREAM; nSamples: longword; var pSample; var pOutput; var pdwOutput: longword): BE_Err; cdecl;
  TbeCloseStream = function(hbeStream: THBE_STREAM): BE_Err; cdecl;
{
function beInitStream(var pbeConfig: TBE_CONFIG; var dwSample: longword; var dwBufferSize: longword; var phbeStream: THBE_STREAM): BE_Err; cdecl; external 'Lame_enc.dll';
function beEncodeChunk(hbeStream: THBE_STREAM; nSamples: longword; var pSample; var pOutput; var pdwOutput: longword): BE_Err; cdecl; external 'Lame_enc.dll';
function beCloseStream(hbeStream: THBE_STREAM): BE_Err; cdecl; external 'Lame_enc.dll';
}

const
  MP3RecorderDurationSA                 : array[TMP3RecorderDuration] of PChar = ('EACH QSO', 'EACH HOUR', 'NON-STOP');
var
  beInitStream                          : TbeInitStream;
  beEncodeChunk                         : TbeEncodeChunk;
  beCloseStream                         : TbeCloseStream;

  LAMEENCDLL                            : HWND;

//function beDeinitStream(hbeStream: THBE_STREAM; var pOutput; var pdwOutput: longword): BE_Err; cdecl; external 'Lame_enc.dll';
//procedure beVersion(var pbeVersion: TBE_VERSION); cdecl; external 'Lame_enc.dll';
//procedure beWriteVBRHeader(pszMP3FileName: PChar); cdecl; external 'Lame_enc.dll';

function MP3RecDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
function InitStrem: boolean;
procedure StartRecorder;
procedure ProcessBuffer(wh: PWaveHdr);
procedure StopRecorder;

procedure SwapRecorderStatus;
procedure OpenTempMP3File;
procedure CloseTempMP3File;
function SaveLastQSOToMP3File(CE: ContestExchangePtr): boolean;
procedure MP3RecorderCallBackFunction(hwi: HWAVEIN; uMsg: UINT; dwInstance: DWORD; dwParam1: DWORD; dwParam2: DWORD);
procedure MP3RecorderThreadProcedure;
function MakeMP3Filename(CE: ContestExchangePtr): PChar;
procedure OpenMCI;

var
  ID3TAG                                : TID3Rec = (Tag: ('T', 'A', 'G'));
  beConfig                              : TBE_Config =
    (
    dwConfig: BE_CONFIG_LAME;
    Format:
    (LHV1:
    (dwStructVersion: 1;
    dwStructSize: SizeOf(TBE_Config);
    dwReSampleRate: 0;
    nMode: BE_MP3_MODE_MONO;
    nPreset: LQP_NORMAL_QUALITY;
    dwMpegVersion: MPEG25;
    bOriginal: True;
    bWriteVBRHeader: True)
    )
    );

  RecorderBitrate                       : Cardinal = 16;
  RecorderEnable                        : boolean;
  RecorderSampleRate                    : integer = 11025;
  RecorderDuration                      : TMP3RecorderDuration = rdEachQSO;



  hLame                                 : THBE_STREAM;

//  pMP3OutputBuffer                      : PByte = nil;
//  pMP3InputBuffer                       : PChar = nil;
  pMP3OutputBuffer                      : array[0..8640 - 1] of Char;
  pMP3InputBuffer                       : array[0..1152 * 2 - 1] of Char;

  MP3InputBufferIndex                   : Cardinal ;

  TempMP3FileHandle                     : HWND;
  BufLen                                : integer;
  bufsize                               : integer;
  Level                                 : integer;

  dwWrite                               : Cardinal;
  ToWrite                               : Cardinal;
  Done                                  : Cardinal;
  TotalSize                             : Cardinal;
  RecorderStartTime                     : Cardinal;
  dwSamples                             : Cardinal;
  dwSamplesMP3                          : Cardinal;

  WaveIn                                : hWaveIn;
  BufHead                               : TWaveHdr;

  Stop                                  : boolean;
  MP3RecorderUsed                       : boolean;
  Header                                : TWaveFormatEx =
    (wFormatTag: WAVE_FORMAT_PCM; nChannels: 1; nBlockAlign: 2; wBitsPerSample: 16; cbSize: 0; );

  hBuf                                  : THandle;

  buf                                   : Pointer;
  MP3RECWNDHND                          : HWND;
  riff                                  :
    array[1..44] of Byte                =
    (
    $52, $49, $46, $46, $74, $75, $0D, $00, {} $57, $41, $56, $45, $66, $6D, $74, $20,
    $10, $00, $00, $00, $01, $00, $01, $00, {} $44, $AC, $00, $00, $88, $58, $01, $00,
    $02, $00, $10, $00, $64, $61, $74, $61, {} $50, $75, $0D, $00
    );

  //PaintFrame                            : HDC;
const

  OUTPUTFILE                            = 'TEMP.MP3';
implementation

uses uCFG, MainUnit;

function MP3RecDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label 1;
begin
  RESULT := False;
  case Msg of
    WM_SIZE, WM_WINDOWPOSCHANGING, WM_EXITSIZEMOVE: DefTR4WProc(Msg, lParam, hwnddlg);

    WM_INITDIALOG:
      begin
        tr4w_WindowsArray[tw_MP3RECORDER].WndHandle := hwnddlg;
        LAMEENCDLL := LoadLibrary('lame_enc.dll');
//        LAMEENCDLL := LoadLibrary('mp3enc.dll');
        if LAMEENCDLL <> 0 then
        begin
          @beInitStream := GetProcAddress(LAMEENCDLL, 'beInitStream');
          @beEncodeChunk := GetProcAddress(LAMEENCDLL, 'beEncodeChunk');
          @beCloseStream := GetProcAddress(LAMEENCDLL, 'beCloseStream');
        end
        else
        begin
          SysErrorMessage(GetLastError);
          asm
          push eax
          end;

          wsprintf(TR4W_TEMP_MP3_FILENAME, 'LAME_ENC.DLL: %s ' + TC_LAME_ERROR + ':' + #13#10#13#10' http://www.tr4w.com/otherfiles');
          asm add esp,12
          end;
          showwarning(TR4W_TEMP_MP3_FILENAME);
          goto 1;
        end;

        MP3RECWNDHND := hwnddlg;

        asm
        push RecorderBitrate
        push RecorderSampleRate
        end;
        wsprintf(TR4W_TEMP_MP3_FILENAME, 'MP3 Recorder (%uHz %ukbps)');
        asm add esp,16
        end;
        Windows.SetWindowText(hwnddlg, TR4W_TEMP_MP3_FILENAME);

        Windows.CreateDirectory(TR4W_MP3PATH, nil);

        if RecorderEnable then
        begin
          SwapRecorderStatus;
          Windows.SendDlgItemMessage(hwnddlg, 101, BM_SETCHECK, BST_CHECKED, 0);
        end;

//        Spectrum := TSpectrum.Create(200, 50);
//        PaintFrame := Windows.GetWindowDC(Windows.GetDlgItem(MP3RECWNDHND, 103));
//        OpenMCI;

      end;

    WM_COMMAND:
      case wParam of
        101: SwapRecorderStatus;
      end;

    WM_NCDESTROY:
      begin
        StopRecorder;
        if LAMEENCDLL <> 0 then FreeLibrary(LAMEENCDLL);
      end;

    WM_CLOSE:
      begin
        1:
        CloseTR4WWindow(tw_MP3RECORDER);
      end;
    MM_WIM_DATA:
      ProcessBuffer(PWaveHdr(lParam));

  end;
end;

procedure MP3RecorderCallBackFunction(hwi: HWAVEIN; uMsg: UINT; dwInstance: DWORD; dwParam1: DWORD; dwParam2: DWORD);
begin
  asm
nop
  end;
end;

procedure MP3RecorderThreadProcedure;
label 1;
begin
  1:
  WaitForSingleObject(tDVP_Event, 30000);
  ProcessBuffer(@BufHead);
  goto 1;
end;

function InitStrem: boolean;
begin
  beConfig.Format.LHV1.dwSampleRate := RecorderSampleRate;
  beConfig.Format.LHV1.dwBitrate := RecorderBitrate;
  RESULT := BeInitStream(BeConfig, dwSamples, dwSamplesMP3, hLame) = BE_ERR_SUCCESSFUL;
//  if pMP3OutputBuffer = nil then GetMem(pMP3OutputBuffer, dwSamplesMP3);
//  if pMP3InputBuffer = nil then GetMem(pMP3InputBuffer, dwSamples * 2);

  OpenTempMP3File;
end;

procedure StartRecorder;
begin
  if not InitStrem then Exit;
  BufSize := dwSamples * RecorderBitrate;
  with Header do
  begin
    nSamplesPerSec := RecorderSampleRate;
//    nBlockAlign := nChannels * (wBitsPerSample div 8);
    nAvgBytesPerSec := nSamplesPerSec * nBlockAlign;
  end;
  WaveInOpen(Addr(WaveIn), WAVE_MAPPER, Addr(Header), MP3RECWNDHND, 0, CALLBACK_WINDOW);
//  WaveInOpen(Addr(WaveIn), WAVE_MAPPER, Addr(Header), Cardinal(@MP3RecorderCallBackFunction), 0, CALLBACK_FUNCTION);

//  WaveInOpen(Addr(WaveIn), WAVE_MAPPER, Addr(Header), Cardinal(tDVP_Event), 0, CALLBACK_EVENT);
//  CreateThread(nil, 0, @MP3RecorderThreadProcedure, nil, 0, tPaddleThreadID);

  BufLen := dwSamples * 8; //Header.nBlockAlign * BufSize;
  hBuf := GlobalAlloc(GMEM_MOVEABLE and GMEM_SHARE, BufLen);
  buf := GlobalLock(hBuf);
  with BufHead do begin
    lpData := buf;
    dwBufferLength := BufLen;
    dwFlags := WHDR_BEGINLOOP;
  end;
  WaveInPrepareHeader(WaveIn, Addr(BufHead), SizeOf(BufHead));
  WaveInAddBuffer(WaveIn, Addr(BufHead), SizeOf(BufHead));

  MP3RecorderUsed := True;
  Stop := True;
  WaveInStart(WaveIn);
end;

procedure ProcessBuffer(wh: PWaveHdr);
var
  ToRead                                : longword;
  a                                     : REAL;
  I                                     : integer;
//  t                                     : TFFTData;
begin
  if MP3RecorderUsed = False then Exit;
  Done := 0;
  //294912
  //2304
  TotalSize := wh.dwBytesRecorded;

//  Windows.LineTo(PaintFrame, 0, 10);
  Windows.SetDlgItemInt(MP3RECWNDHND, 103, PWORD(wh.lpData)^ div 200, False);
  a := 0;
//  for I := 0 to 2304-2 do    a := a + PWORD(@wh.lpData[I * 2])^ * cos((2 * pi * I * 1000) / 2304);

//  Windows.SetDlgItemInt(MP3RECWNDHND, 103, round(a/1000), False);

  while Done < TotalSize do
  begin
    beEncodeChunk(hLame, dwSamples, wh.lpData[Done], pMP3OutputBuffer[0], toWrite);
    WriteFile(TempMP3FileHandle, pMP3OutputBuffer[0], toWrite, dwWrite, nil);
    if toWrite <> dwWrite then sm;
    Done := Done + dwSamples * SizeOf(SHORT);
  end;
//  Windows.CopyMemory(@t, wh.lpData, sizeof(TFFTData));
//  Spectrum.draw(PaintFrame, t, -40, -60);

//  WriteFile(TempMP3FileHandle, wh.lpData[0], TotalSize, dwWrite, nil);
{
  if MP3InputBufferIndex = 0 then WriteFile(TempMP3FileHandle, riff, 44, dwWrite, nil);
  if MP3InputBufferIndex < 10 then WriteFile(TempMP3FileHandle, wh.lpData[0], TotalSize, dwWrite, nil);
  inc(MP3InputBufferIndex);
}
{
  while Done < (TotalSize - dwSamples * SizeOf(SHORT)) do
  begin
    Windows.CopyMemory(@pMP3InputBuffer[MP3InputBufferIndex], @wh.lpData[Done], dwSamples * SizeOf(SHORT) - MP3InputBufferIndex);
    beEncodeChunk(hLame, dwSamples, pMP3InputBuffer, pMP3OutputBuffer^, toWrite);
    WriteFile(TempMP3FileHandle, pMP3OutputBuffer^, toWrite, dwWrite, nil);
    Done := Done + dwSamples * SizeOf(SHORT) - MP3InputBufferIndex;
    MP3InputBufferIndex := 0;
  end;
}
{
  MP3InputBufferIndex := TotalSize - Done;
  Windows.ZeroMemory(@pMP3InputBuffer[0], SizeOf(pMP3InputBuffer));
  Windows.CopyMemory(@pMP3InputBuffer[0], @wh.lpData[Done], MP3InputBufferIndex);
}
  if Stop then WaveInAddBuffer(WaveIn, wh, SizeOf(TWaveHdr)) else Stop := True;

  Windows.SetDlgItemText(MP3RECWNDHND, 102, MillisecondsToFormattedString(Windows.GetTickCount - RecorderStartTime, False));
end;

procedure StopRecorder;
begin
  if MP3RecorderUsed = False then Exit;
  if Stop = False then Exit;
  CloseTempMP3File;
  Stop := False;
  WaveInReset(WaveIn);
  WaveInUnPrepareHeader(WaveIn, Addr(BufHead), SizeOf(BufHead));
  WaveInClose(WaveIn);
  GlobalUnlock(hBuf);
  GlobalFree(hBuf);
//  FreeMem(pMP3OutputBuffer);
//  pMP3OutputBuffer := nil;
  beCloseStream(hLame);
  MP3RecorderUsed := False;
  Windows.SetDlgItemText(MP3RECWNDHND, 102, nil);
  Windows.SetDlgItemText(MP3RECWNDHND, 103, nil);
end;

procedure SwapRecorderStatus;
begin
  if MP3RecorderUsed then
  begin
    StopRecorder;
  end
  else
  begin
    StartRecorder;
  end;
end;

procedure OpenTempMP3File;
begin
  asm
  xor eax,eax
  mov ax, word ptr UTC.wDay
  push eax

  xor eax,eax
  mov ax, word ptr UTC.wHour
  push eax

  lea eax,TR4W_MP3PATH
  push eax
  end;
  wsprintf(TR4W_TEMP_MP3_FILENAME, '%s\TEMP_%02u_%02u.MP3');
  asm add esp,20
  end;

  RecorderStartTime := Windows.GetTickCount;
  TempMP3FileHandle := CreateFile(TR4W_TEMP_MP3_FILENAME, GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
end;

procedure CloseTempMP3File;
begin
  CloseHandle(TempMP3FileHandle);
end;

function MakeMP3Filename(CE: ContestExchangePtr): PChar;
var
  Callsign                              : PChar;
  Band                                  : PChar;

  Year                                  : Cardinal;
  Hour                                  : Cardinal;
  Month                                 : Cardinal;
  Day                                   : Cardinal;
  Minutes                               : Cardinal;
  Seconds                               : Cardinal;
begin
  Year := CE.tSysTime.qtYear + 2000;
  Callsign := @CE.Callsign[1];
  Band := BandStringsArrayWithOutSpaces[CE.Band];
  Seconds := CE.tSysTime.qtSecond;
  Minutes := CE.tSysTime.qtMinute;
  Hour := CE.tSysTime.qtHour;
  Day := CE.tSysTime.qtDay;
  Month := CE.tSysTime.qtMonth;
  asm
  push Callsign
  push Band
  push Seconds
  push Minutes
  push Hour
  push Day
  push Month
  push Year
  lea eax,TR4W_MP3PATH
  push eax
  end;
  wsprintf(TR4W_GET_MP3_FILENAME, '%s\%u%02u%02u_%02u%02u%02u_%sm_%s.MP3');
  asm add esp,44  end;

  RESULT := TR4W_GET_MP3_FILENAME;
end;

function SaveLastQSOToMP3File(CE: ContestExchangePtr): boolean;
var
  Callsign                              : PChar;
  Year                                  : Cardinal;
{  Band                                  : PChar;

  Hour                                  : Cardinal;
  Month                                 : Cardinal;
  Day                                   : Cardinal;
  Minutes                               : Cardinal;
  Seconds                               : Cardinal;
 }TempInteger                           : integer;
  FileName                              : PChar;
begin
  RESULT := False;
  if not MP3RecorderUsed then Exit;
  if tr4w_WindowsArray[tw_MP3RECORDER].WndHandle = 0 then Exit;

  Windows.ZeroMemory(@ID3TAG.Title, SizeOf(ID3TAG) - SizeOf(ID3TAG.Tag));

  Year := CE.tSysTime.qtYear + 2000;
  Callsign := @CE.Callsign[1];
//  Band := BandStringsArrayWithOutSpaces[CE.Band];
//  Seconds := CE.tSysTime.qtSecond;
//  Minutes := CE.tSysTime.qtMinute;
//  Hour := CE.tSysTime.qtHour;
//  Day := CE.tSysTime.qtDay;
//  Month := CE.tSysTime.qtMonth;

  asm
  push Year
  end;
  wsprintf(@ID3TAG.Year, '%u');
  asm add esp,12
  end;

  asm
  push Callsign
  end;
  wsprintf(@ID3TAG.Artist, 'QSO with %s');
  asm add esp,12 end;

  Windows.lstrcpy(@ID3TAG.Album, ContestTypeSA[Contest]);
  Windows.lstrcpy(@ID3TAG.comment, TR4W_CURRENTVERSION);
  Windows.lstrcpy(@ID3TAG.Title, @MyCall[1]);
  ID3TAG.Genre := $1C;

  SetFilePointer(TempMP3FileHandle, 0, nil, FILE_END);
  sWriteFile(TempMP3FileHandle, ID3TAG, SizeOf(ID3TAG));

  CloseTempMP3File;
{
  asm
  push Callsign
  push Band
  push Seconds
  push Minutes
  push Hour
  push Day
  push Month
  push Year
  lea eax,[MP3Path+1]
  push eax
  end;
  wsprintf(TR4W_CURR_MP3_FILENAME, '%s\%u%02u%02u_%02u%02u%02u_%sm_%s.MP3');
  asm add esp,44  end;
}
  FileName := MakeMP3Filename(CE);
  DeleteSlashes(FileName);

  Windows.CopyFile(TR4W_TEMP_MP3_FILENAME, FileName, True);
  OpenTempMP3File;
  RESULT := True;
end;

procedure OpenMCI;
var
  wDeviceID                             : UINT;
  dwReturn                              : DWORD;
  mciOpenParms                          : MCI_OPEN_PARMS;
  mciPlayParms                          : MCI_PLAY_PARMS;

  mciOpen                               : MCI_DGV_OPEN_PARMS;

  hwndMovie                             : HWND;
begin

  hwndMovie := CreateWindow('mywindow', 'Playback', WS_CHILD + WS_BORDER, 0, 0, 200, 100, tr4whandle, 0, hInstance, nil);
{
  DeviceName: array[TMPDeviceTypes] of PChar = ('', 'AVIVideo', 'CDAudio', 'DAT',
    'DigitalVideo', 'MMMovie', 'Other', 'Overlay', 'Scanner', 'Sequencer',
    'VCR', 'Videodisc', 'WaveAudio');
}

  mciOpen.lpstrDeviceType := '';
  mciOpen.lpstrElementName := 'D:\TR4W_WinAPI\out\TEST\MP3\20090909_050655_10m_UA0QBR.MP3';
  mciOpen.dwStyle := WS_CHILD;
  mciOpen.hwndParent := tr4whandle;

  mciGetErrorString(mciSendCommand(0, MCI_OPEN, MCI_OPEN_ELEMENT + MCI_DGV_OPEN_PARENT + MCI_DGV_OPEN_32BIT, Cardinal(@mciOpen)), wsprintfBuffer, 2000);
  wDeviceID := mciOpen.wDeviceID;

  mciPlayParms.dwCallback := DWORD(MP3RECWNDHND);
  mciSendCommand(wDeviceID, MCI_PLAY, MCI_NOTIFY, DWORD(@mciPlayParms));

//  ShowMessage(wsprintfBuffer);

{
  mciOpenParms.lpstrDeviceType := '';
  mciOpenParms.lpstrElementName := 'D:\TR4W_WinAPI\out\TEST\MP3\20090909_050655_10m_UA0QBR.MP3';
  mciGetErrorString(mciSendCommand(0, MCI_OPEN, MCI_OPEN_ELEMENT, Cardinal(@mciOpenParms)), wsprintfBuffer, 2000);
  //ShowMessage(wsprintfBuffer);
  wDeviceID := mciOpenParms.wDeviceID;
  mciPlayParms.dwCallback := DWORD(MP3RECWNDHND);
  if mciSendCommand(wDeviceID, MCI_PLAY, MCI_NOTIFY, DWORD(@mciPlayParms)) = 0 then
}
end;

begin
//  showint(SizeOf(TBE_Config));
//  TLHV1 =  64
//  TMP3 = 23
//TAAC = 8
end.

