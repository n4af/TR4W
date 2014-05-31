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

const
  Freq                                  = 22100;
  bufsize                               = Freq * 2;

  rec                                   = 01;
  Stop                                  = 00;

type Tbuffer = array[0..bufsize - 1] of Smallint;

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
procedure StartRecorder2;
procedure StartRecorder;

procedure ProcessBuffer(wh: PWaveHdr);
procedure waveInProc2(hwi: HWAVEIN; uMsg: UINT; dwInstance: DWORD; dwParam1: DWORD; dwParam2: DWORD); stdcall;
procedure waveInProc(hwi: HWAVEIN; uMsg: UINT; dwInstance: DWORD; dwParam1: DWORD; dwParam2: DWORD); stdcall;

procedure EncodeThreadProc;
procedure StopRecorder2;
procedure StopRecorder;

procedure SwapRecorderStatus;
procedure OpenTempMP3File;
procedure CloseTempMP3File;
function SaveLastQSOToMP3File(CE: ContestExchangePtr): boolean;
procedure MP3RecorderCallBackFunction(hwi: HWAVEIN; uMsg: UINT; dwInstance: DWORD; dwParam1: DWORD; dwParam2: DWORD);
procedure MP3RecorderThreadProcedure;
function MakeMP3Filename(CE: ContestExchangePtr): PChar;
procedure OpenMCI;
procedure CheckMMError(ErrorCode: Cardinal);

var
  TotalBytesInWAVFile                   : integer;
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
    dwMpegVersion: MPEG1; //MPEG25;
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

  MP3InputBufferIndex                   : Cardinal;

  TempMP3FileHandle                     : HWND;
  BufLen                                : integer;
  bufsize2                              : integer;
  Level                                 : integer;

  dwWrite                               : Cardinal;
  ToWrite                               : Cardinal;

//  TotalSize                             : Cardinal;
  RecorderStartTime                     : Cardinal;
  dwSamples                             : Cardinal;
  dwMP3Buffer                           : Cardinal;

  WaveIn                                : hWaveIn;

  EncodeBuffer                          : array[0..400000] of Char;
  EncodeBufferReadPos, EncodeBufferWritePos: Cardinal;

  EncodeEvent                           : Cardinal;
  EncodeThreadID                        : Cardinal;

  BufHead1                              : TWaveHdr;
  BufHead2                              : TWaveHdr;

//  StopRecord                            : boolean;
  MP3RecorderUsed                       : boolean;
  Header                                : TWaveFormatEx;

  hBuf1                                 : THandle;
  buf1                                  : Pointer;

  hBuf2                                 : THandle;
  buf2                                  : Pointer;

  Address                               : pWaveHdr;

  MP3RECWNDHND                          : HWND;

  TempWavHeader                         : WavHeader =
    (
    Marker1: ('R', 'I', 'F', 'F');
    Marker2: ('W', 'A', 'V', 'E');
    Marker3: ('f', 'm', 't', ' ');
    Fixed1: 16;
    FormatTag: 1;
    Channels: 1;
    SampleRate: Freq;
    BytesPerSecond: Freq * 2;
    BytesPerSample: 2;
    BitsPerSample: 16;
    Marker4: ('d', 'a', 't', 'a');
    )
    ;

  riff                                  :
    array[1..44] of Byte                =
    (
    $52, $49, $46, $46, $74, $75, $0D, $00, {} $57, $41, $56, $45, $66, $6D, $74, $20,
    $10, $00, $00, $00, $01, $00, $01, $00, {} $44, $AC, $00, $00, $88, $58, $01, $00,
    $02, $00, $10, $00, $64, $61, $74, $61, {} $50, $75, $0D, $00
    );

  Buffer                                : array[0..1] of Tbuffer; //двойной аудио-буфер
  whead                                 : array[0..1] of twavehdr; //заголовок для аудио-буфера
  wfx                                   : TWAVEFORMATEX;
  hwi                                   : HWAVEin;
  Mode                                  : integer;

  //PaintFrame                            : HDC;
const

  OUTPUTFILE                            = 'TEMP.MP3';
implementation

uses uCFG, MainUnit;

function MP3RecDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label 1;
begin
  Result := False;
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
  ProcessBuffer(@BufHead1);
  goto 1;
end;

function InitStrem: boolean;
begin
  beConfig.Format.LHV1.dwSampleRate := Freq; //RecorderSampleRate;
  beConfig.Format.LHV1.dwBitrate := RecorderBitrate;
  Result := BeInitStream(beConfig, dwSamples, dwMP3Buffer, hLame) = BE_ERR_SUCCESSFUL;
//  if pMP3OutputBuffer = nil then GetMem(pMP3OutputBuffer, dwSamplesMP3);
//  if pMP3InputBuffer = nil then GetMem(pMP3InputBuffer, dwSamples * 2);

  OpenTempMP3File;
end;

procedure StartRecorder;
var
  i                                     : Byte;
  Err                                   : MMRESULT;
begin
  if not InitStrem then Exit;

//  WriteFile(TempMP3FileHandle, TempWavHeader, SizeOf(TempWavHeader), dwWrite, nil);

  for i := 0 to 1 do begin
    whead[i].lpData := @Buffer[i];
    whead[i].dwBufferLength := bufsize;
    whead[i].dwFlags := 0;
  end;
  wfx.wFormatTag := WAVE_FORMAT_PCM;
  wfx.nChannels := 1;
  wfx.nSamplesPerSec := Freq;
  wfx.wBitsPerSample := 16;
  wfx.nBlockAlign := wfx.nChannels * (wfx.wBitsPerSample shr 3);
  wfx.nAvgBytesPerSec := wfx.nSamplesPerSec * wfx.nBlockAlign;
  wfx.cbSize := 0;

  err := waveinopen(@hwi, wave_mapper, @wfx, DWORD(@waveinproc), 0, callback_function);
//  if err = mmsyserr_noerror then form1.Caption := 'open';

  for i := 0 to 1 do waveinprepareheader(hwi, @whead[i], SizeOf(whead[i]));
  for i := 0 to 1 do waveinaddbuffer(hwi, @whead[i], SizeOf(whead[i]));
  Mode := rec;
  waveinstart(hwi);
  MP3RecorderUsed := True;
end;

procedure StartRecorder2;
var
  ErrorCode                             : Cardinal;
begin
  if not InitStrem then Exit;
  if EncodeEvent = 0 then EncodeEvent := Windows.CreateEvent(nil, False, False, nil);

  BufSize2 := 22050; //dwSamples * RecorderBitrate;
  with Header do
  begin
    wFormatTag := WAVE_FORMAT_PCM;
    nChannels := 1;
    nSamplesPerSec := RecorderSampleRate;
    wBitsPerSample := 16;
    nBlockAlign := nChannels * (wBitsPerSample div 8);
    nAvgBytesPerSec := nSamplesPerSec * nBlockAlign;
    cbSize := 0;
  end;
//  ErrorCode := WaveInOpen(Addr(WaveIn), WAVE_MAPPER, Addr(Header), MP3RECWNDHND, 0, CALLBACK_WINDOW);
  ErrorCode := WaveInOpen(@WaveIn, WAVE_MAPPER, Addr(Header), Cardinal(@waveInProc), 0, CALLBACK_FUNCTION);
  CheckMMError(ErrorCode);

//  WaveInOpen(Addr(WaveIn), WAVE_MAPPER, Addr(Header), Cardinal(@MP3RecorderCallBackFunction), 0, CALLBACK_FUNCTION);

//  WaveInOpen(Addr(WaveIn), WAVE_MAPPER, Addr(Header), Cardinal(tDVP_Event), 0, CALLBACK_EVENT);
//  CreateThread(nil, 0, @MP3RecorderThreadProcedure, nil, 0, tPaddleThreadID);

//  BufLen := dwSamples * 8; //Header.nBlockAlign * BufSize;
  BufLen := Header.nBlockAlign * BufSize;

  hBuf1 := GlobalAlloc(GMEM_MOVEABLE and GMEM_SHARE, BufLen);
  buf1 := GlobalLock(hBuf1);
  with BufHead1 do begin
    lpData := buf1;
    dwBufferLength := BufLen;
    dwFlags := 0;
  end;

  hBuf2 := GlobalAlloc(GMEM_MOVEABLE and GMEM_SHARE, BufLen);
  buf2 := GlobalLock(hBuf2);
  with BufHead2 do begin
    lpData := buf2;
    dwBufferLength := BufLen;
    dwFlags := 0;
  end;

  Address := @BufHead1;

  ErrorCode := WaveInPrepareHeader(WaveIn, Addr(BufHead1), SizeOf(TWaveHdr));
  CheckMMError(ErrorCode);

  ErrorCode := WaveInPrepareHeader(WaveIn, Addr(BufHead2), SizeOf(TWaveHdr));
  CheckMMError(ErrorCode);

  ErrorCode := WaveInAddBuffer(WaveIn, Addr(BufHead1), SizeOf(TWaveHdr));
  CheckMMError(ErrorCode);

  WriteFile(TempMP3FileHandle, TempWavHeader, SizeOf(TempWavHeader), dwWrite, nil);
  tCreateThread(@EncodeThreadProc, EncodeThreadID);

  MP3RecorderUsed := True;
//  StopRecord := True;
  ErrorCode := WaveInStart(WaveIn);
  CheckMMError(ErrorCode);
end;

procedure waveInProc;
var i                                   : Byte;
  Done                                  : integer;
begin
  case uMsg of
    wim_open: begin
      end;
    wim_data: for i := 0 to 1 do begin
        if ((whead[i].dwFlags and WHDR_DONE) = WHDR_DONE) and
          (Mode = rec) then begin

//          WriteFile(TempMP3FileHandle, whead[i].lpData^, whead[i].dwBytesRecorded, dwWrite, nil);
//          inc(TotalBytesInWAVFile, whead[i].dwBytesRecorded);
          Done := 0;
          while Done < whead[i].dwBytesRecorded do
          begin
            beEncodeChunk(hLame, dwSamples, whead[i].lpData[Done], pMP3OutputBuffer[0], toWrite);
            WriteFile(TempMP3FileHandle, pMP3OutputBuffer[0], toWrite, dwWrite, nil);
            if toWrite <> dwWrite then sm;
            Done := Done + dwSamples * SizeOf(SHORT);
          end;

                            //------------------------------
                            // в этом месте обработка буфера
                            //------------------------------
          waveinaddbuffer(hwi, @whead[i], SizeOf(whead[i]));
        end;
      end;

    wim_close: begin
      end;
  end;
end;

procedure waveInProc2(hwi: HWAVEIN; uMsg: UINT; dwInstance: DWORD; dwParam1: DWORD; dwParam2: DWORD); stdcall;
begin

  if uMsg = WIM_DATA then
  begin
    ProcessBuffer(PWaveHdr(dwParam1));
  end;

end;

procedure ProcessBuffer(wh: PWaveHdr);
var
  temp                                  : pWaveHdr;
  Done                                  : Cardinal;
begin
  if MP3RecorderUsed = False then Exit;

  temp := Address;
  if Address = @BufHead1 then Address := @BufHead2 else Address := @BufHead1;
  if MP3RecorderUsed then waveInAddBuffer(WaveIn, Address, SizeOf(TWaveHdr));

//   recorded:=address.dwBytesRecorded;
// записываем блок
//   BlockWrite(fOut,(temp.lpData)^,address.dwBytesRecorded);

//  WriteFile(TempMP3FileHandle, temp.lpData^, Address.dwBytesRecorded, dwWrite, nil);
{
  while Done < Address.dwBytesRecorded do
  begin
    beEncodeChunk(hLame, dwSamples, temp.lpData[Done], pMP3OutputBuffer[0], toWrite);
    WriteFile(TempMP3FileHandle, pMP3OutputBuffer[0], toWrite, dwWrite, nil);
    if toWrite <> dwWrite then sm;
    Done := Done + dwSamples * SizeOf(SHORT);
  end;
}

  WriteFile(TempMP3FileHandle, temp.lpData^, temp.dwBytesRecorded, dwWrite, nil);
  inc(TotalBytesInWAVFile, wh.dwBytesRecorded);

{
  Windows.CopyMemory(@EncodeBuffer[EncodeBufferWritePos * temp.dwBytesRecorded], temp.lpData, temp.dwBytesRecorded);
  inc(EncodeBufferWritePos);
  if EncodeBufferWritePos = 5 then EncodeBufferWritePos := 0;
  Windows.SetEvent(EncodeEvent);
}
  Windows.SetDlgItemInt(MP3RECWNDHND, 103, {PWORD(wh.lpData)^ div 655} EncodeBufferWritePos, False);

  //Windows.SetDlgItemText(MP3RECWNDHND, 102, MillisecondsToFormattedString(Windows.GetTickCount - RecorderStartTime, False));
end;

procedure EncodeThreadProc;
label NextWait;
var
  Done                                  : Cardinal;
begin
  NextWait:
  Windows.WaitForSingleObject(EncodeEvent, INFINITE);
  if not MP3RecorderUsed then
  begin
    asm nop end;
    Exit;
  end;
  Done := 0;
  WriteFile(TempMP3FileHandle, EncodeBuffer[EncodeBufferReadPos * 9216], 9216, dwWrite, nil);
{
  while Done < BufLen do
  begin
    beEncodeChunk(hLame, dwSamples, EncodeBuffer[Done + EncodeBufferReadPos * BufLen], pMP3OutputBuffer[0], toWrite);
    WriteFile(TempMP3FileHandle, pMP3OutputBuffer[0], toWrite, dwWrite, nil);
    Done := Done + dwSamples * SizeOf(SHORT);
  end;
}
  inc(EncodeBufferReadPos);
  if EncodeBufferReadPos = 5 then EncodeBufferReadPos := 0;
  Windows.SetDlgItemInt(MP3RECWNDHND, 102, EncodeBufferReadPos, False);
  goto NextWait;
end;

procedure StopRecorder;
var i                                   : Byte;
begin
{
  SetFilePointer(TempMP3FileHandle, 0, nil, FILE_BEGIN);
  TempWavHeader.BytesFollowing := TotalBytesInWAVFile + 44 - 8;
  TempWavHeader.DataBytes := TotalBytesInWAVFile;
  WriteFile(TempMP3FileHandle, TempWavHeader, SizeOf(TempWavHeader), dwWrite, nil);
  CloseHandle(TempMP3FileHandle);
}
  Mode := Stop;
  waveinreset(hwi);
  for i := 0 to 1 do waveinunprepareheader(hwi, @whead[i], SizeOf(whead[i]));
  waveinclose(hwi);
end;

procedure StopRecorder2;
begin
  if MP3RecorderUsed = False then Exit;
  MP3RecorderUsed := False;
  Windows.SetEvent(EncodeEvent);
//  Sleep(000);

//  if StopRecord = False then Exit;

  SetFilePointer(TempMP3FileHandle, 0, nil, FILE_BEGIN);
  TempWavHeader.BytesFollowing := TotalBytesInWAVFile + 44 - 8;
  TempWavHeader.DataBytes := TotalBytesInWAVFile;
  WriteFile(TempMP3FileHandle, TempWavHeader, SizeOf(TempWavHeader), dwWrite, nil);

  WaveInReset(WaveIn);

  CloseTempMP3File;
//  StopRecord := False;

  WaveInUnPrepareHeader(WaveIn, Addr(BufHead1), SizeOf(TWaveHdr));
  WaveInUnPrepareHeader(WaveIn, Addr(BufHead1), SizeOf(TWaveHdr));

  WaveInClose(WaveIn);
  GlobalUnlock(hBuf1);
  GlobalFree(hBuf1);
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

  Result := TR4W_GET_MP3_FILENAME;
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
  Result := False;
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
  Result := True;
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

procedure CheckMMError(ErrorCode: Cardinal);
begin
  if ErrorCode = MMSYSERR_NOERROR then Exit;
  waveInGetErrorText(ErrorCode, @wsprintfBuffer, SizeOf(wsprintfBuffer));
  showwarning(wsprintfBuffer);
end;

begin
//  showint(SizeOf(TBE_Config));
//  TLHV1 =  64
//  TMP3 = 23
//TAAC = 8
end.

