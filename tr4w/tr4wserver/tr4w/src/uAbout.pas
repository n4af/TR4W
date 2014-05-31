unit uAbout;
{$IMPORTEDDATA OFF}
interface

uses

  TF,
  VC,
  LogDupe,
  OpenGL,
  Messages,
  Windows;

function AboutDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
procedure MainProc();

var
  OGLDC                                 : HDC;
  pfd                                   : PIXELFORMATDESCRIPTOR;
  PixelFormat                           : integer;
  Context                               : HGLRC;
  myFont                                : Cardinal;
  listBase                              : Cardinal = $00401AB8;
  theta                                 : single;
  delta                                 : single = 0.4;
  delta2                                : single = -1;
  txtIntro                              : array[0..3] of Char = (#32, #30, #0, #35);
  tid                                   : Cardinal;

const
  ratio                                 = 0.56;
var
  AboutHWND                             : HWND;

implementation
uses MainUnit;

function AboutDlgProc(hwnddlg: HWND; Msg: UINT; wParam: wParam; lParam: lParam): BOOL; stdcall;
label 1;
begin
  RESULT := False;
  case Msg of
    WM_INITDIALOG:
      begin
        AboutHWND := hwnddlg;
        CreateThread(nil, 0, @MainProc, nil, 0, tid);
        Windows.SetDlgItemText(hwnddlg, 102, tAboutText);
      end;
    WM_COMMAND: if wParam = 2 then goto 1;
    WM_CLOSE:
      begin
        1:
        tid := 0;
        Sleep(50);
        EndDialog(AboutHWND, 0);
      end;
    WM_CTLCOLORDLG, WM_CTLCOLORSTATIC:
      begin
        SetBkMode(HDC(wParam), TRANSPARENT);
        SetTextColor(HDC(wParam), $00FFFFFF);
        RESULT := LongBool(tr4wBrushArray[trBlack]);
        Exit;
      end;

  end;

end;

procedure MainProc();
label draw;
begin
  OGLDC := Windows.GetDC(Windows.GetDlgItem(AboutHWND, 101));
  pfd.dwFlags := PFD_DRAW_TO_WINDOW + PFD_SUPPORT_OPENGL + PFD_DOUBLEBUFFER;
  pfd.iPixelType := PFD_TYPE_RGBA;
  pfd.cColorBits := 32;
  pfd.dwLayerMask := PFD_MAIN_PLANE;
  PixelFormat := ChoosePixelFormat(OGLDC, @pfd);
  SetPixelFormat(OGLDC, PixelFormat, @pfd);
  Context := wglCreateContext(OGLDC);
  wglMakeCurrent(OGLDC, Context);
  glEnable(GL_BLEND);
  glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

  glEnable(GL_LIGHT1);

//  glEnable(GL_LIGHTING);
  glEnable(GL_COLOR_MATERIAL);

  myFont := CreateFont(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 'ARIAL');
  SelectObject(OGLDC, myFont);

  wglUseFontOutlinesA(OGLDC, 52, 36, listbase, 0, 0.2, WGL_FONT_POLYGONS, nil);
  glListBase(listBase);

  glTexImage2D(GL_TEXTURE_2D, 0, 4, 16, 16, 0, GL_RGBA, GL_UNSIGNED_BYTE, @tr4w_ClassName[3]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
  glTexGeni(GL_S, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glTexGeni(GL_T, GL_TEXTURE_GEN_MODE, GL_SPHERE_MAP);
  glEnable(GL_TEXTURE_GEN_S);
  glEnable(GL_TEXTURE_GEN_T);
  glEnable(GL_TEXTURE_2D);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
  glMatrixMode(GL_PROJECTION);
  gluPerspective(60.0, ratio, 0.1, 20.0);
  glMatrixMode(GL_MODELVIEW);
//  glClearColor(1, 1, 1, 1);
  glColor4f(0, 0, 1, 100);

  draw:

  glClear(GL_COLOR_BUFFER_BIT);
  glLoadIdentity;

  glTranslatef(-1.0, 0, -2);

//  delta2 := delta2 + 1;
  glRotatef(theta, delta2, delta2, delta2 * 1);
//  glRotatef(theta, 1, 0, 0);
//  glRotatef(theta, 0, 1, 0);
//  glRotatef(theta, 1, 0, 0);
//  if (theta > 0) and (theta < 90) then glRotatef(theta, delta2, 1, delta2);
//  if (theta > 90) and (theta < 270) then delta := delta+0.2 else delta := 0.5;
//  if theta > 360 then begin theta := 0;end;
//  if theta > 360 then begin theta := 0;end;
//  if theta > 90 then   glRotatef(180, 0, 0, 0);

//  glTranslatef(-1.3, -0.15, 0.15);

  glCallLists(4, GL_UNSIGNED_BYTE, @txtIntro);
  asm
  fld [theta]
  fadd [delta]
  fstp [theta]
  end;

//  Windows.SetDlgItemInt(AboutHWND, 102, round(theta), False);
  SwapBuffers(OGLDC);
  Sleep(10);
  if tid = 0 then Exit;
  goto draw;
  DeleteObject(myFont);

  wglMakeCurrent(OGLDC, 0);
  wglDeleteContext(Context);
  ReleaseDC(AboutHWND, OGLDC);

end;

end.

