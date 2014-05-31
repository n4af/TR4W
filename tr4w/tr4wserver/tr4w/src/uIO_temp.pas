{===========================================================================
 Этот модуль содержит функции для обращения к драйверу LPTWDMIO.SYS
 Автор: Гречко Ю.Б., http://progrex.narod.ru, 2003г.
 Статус: freeware.
 ===========================================================================
 Bugtrack:

 25.08.2002 -- Добавлены деклараторы для описания отдельных бит в регистрах LPT,
 Добавлена секция для самозагрузки драйвера под Windows NT/2000/XP

 27.08.2002 -- Добавлена поддержка регистров данных и адреса EPP и поддержка
 прямого ввода-вывода на платформах Windows 9X.

 01.02.2003 -- Исправлена ошибка в процедурах Writepk и Readpk (цикл по структурам)

 14.04.2002 -- Исправлена ошибка в функции IsPortBidirectional

 ===========================================================================}
unit uIO;

interface
uses TF, VC, WinSvc, Windows {, SysUtils, Forms};

{$IMPORTEDDATA OFF}

{
READ_PORT_UCHAR
The READ_PORT_UCHAR macro reads a byte from the specified port address.

UCHAR
  READ_PORT_UCHAR(
    IN PUCHAR  Port
    );
Parameters

Port
Specifies the port address, which must be a mapped memory range in I/O space.
Return Value

READ_PORT_UCHAR returns the byte that is read from the specified port address.

Comments

Callers of READ_PORT_UCHAR can be running at any IRQL, assuming the Port is resident, mapped device memory.
}

{
WRITE_PORT_UCHAR
The WRITE_PORT_UCHAR macro writes a byte to the specified port address.

VOID
  WRITE_PORT_UCHAR(
    IN PUCHAR  Port,
    IN UCHAR  Value
    );
Parameters

Port
Pointer to the port, which must be a mapped memory range in I/O space.
Value
Specifies a byte to be written to the port.
Return Value

None

Comments

Callers of WRITE_PORT_UCHAR can be running at any IRQL, assuming the Port is resident, mapped device memory.
}

type
  TOffsetType = (otData, otState, otControl);
  TBitOperation = (boSet0, boSet1);
  TBitSet = (bsBIT0, bsBIT1, bsBIT2, bsBIT3, bsBIT4, bsBIT5, bsBIT6, bsBIT7);
//control = 1,14,16,17
const
  DRV_BINARY_PATH_NAME                  : PChar = 'SYSTEM32\DRIVERS\TR4WIO.SYS';
  DRV_LINK_NAME                         : PChar = '\\.\TR4WIOAccess';

  STROBE_SIGNAL                         = bsBIT0; //PIN 01 INVERTED
  PTT_SIGNAL                            = bsBIT2; //PIN 16
  CW_SIGNAL                             = bsBIT3; //PIN 17 INVERTED
  RELAY_SIGNAL                          = bsBIT1; //PIN 14

 { Коды сообщений драйверу }
  IOCTL_READ_PORTS                      : Cardinal = $00220050; // Чтение регистров LPT
  IOCTL_WRITE_PORTS                     : Cardinal = $00220060; // Запись в регистры LPT

  BIT0                                  : Byte = $01;
  BIT1                                  : Byte = $02;
  BIT2                                  : Byte = $04;
  BIT3                                  : Byte = $08;
  BIT4                                  : Byte = $10;
  BIT5                                  : Byte = $20;
  BIT6                                  : Byte = $40;
  BIT7                                  : Byte = $80;

  // Printer Port pin numbers
  ACK_PIN                               : Byte = 10;
  BUSY_PIN                              : Byte = 11;
  PAPEREND_PIN                          : Byte = 12;
  SELECTOUT_PIN                         : Byte = 13;
  ERROR_PIN                             : Byte = 15;
  STROBE_PIN                            : Byte = 1;
  AUTOFD_PIN                            : Byte = 14;
  INIT_PIN                              : Byte = 16;
  SELECTIN_PIN                          : Byte = 17;

 { Смещения регистров порта }
  LPT_DATA_REG                          : Byte = 0; // Регистр данных
  LPT_STATE_REG                         : Byte = 1; // Регистр состояния
  LPT_CONTROL_REG                       : Byte = 2; // Регистр управления
  LPT_EPP_ADDRESS                       : Byte = 3; // Регистр адреса EPP
  LPT_EPP_DATA                          : Byte = 4; // Регистр данных EPP

 { Битовые расклады регистров / разъём 25 pin / разъём Centronic }
 { Битовый расклад регистра УПРАВЛЕНИЯ }
  STROBE                                : Byte = $01; { Строб,          1 /1             }
  AUTOFEED                              : Byte = $02; { Автопротяжка,   14/14            }
  Init                                  : Byte = $04; { Инициализация,  16/31            }
  SELECTIN                              : Byte = $08; { Выбор принтера, 17/36            }
  IRQE                                  : Byte = $10; { Прерывание,     ------           }
  Direction                             : Byte = $20; { Направление ШД, ------           }

 { Битовый расклад регистра СОСТОЯНИЯ }
  IRQS                                  : Byte = $04; { Флаг прерывания,------           }
  ERROR                                 : Byte = $08; { Признак ошибки, 15/32            }
  SELECT                                : Byte = $10; { Признак выбора, 13/13            }
  PAPEREND                              : Byte = $20; { Конец бумаги,   12/12            }
  ACK                                   : Byte = $40; { Готовность к приёму данных, 10/10}
  BUSY                                  : Byte = $80; { Занятость,      11/11            }

 { Константы для работы с менеджером сервисов }
//  SC_MANAGER_ALL_ACCESS                 : Cardinal = $000F003F;
//  SERVICE_ALL_ACCESS                    : Cardinal = $000F01FF;

  SWC_NAME                              : PChar = 'TR4WIO'; //'lptwdmio'; { Системное имя сервиса }
  SWC_DISPLAY_NAME                      : PChar = 'TR4W IO Access'; //'LPT port direct access service'; { Название сервиса, чтобы показать пользователю :) }

var
 { Класс для обращения к драйверу LPTWDMIO.sys }
//  TDriverConnection = class
//  private
  DriverFailedToLoad                    : boolean;
  DriverHandle                          : Cardinal = INVALID_HANDLE_VALUE; // Хэндл загруженного драйвера
  DriverWinNT                           : boolean = True; // Признак платформы NT

  { Данные, относящиеся к вызову менеджера сервисов на платформах NT }
//  UnregisterService                     : boolean; // флаг, показывающий необходимость удаления сервиса lptwdmio по закрытии приложения в Win NT

  ServiceArgVectors                     : PChar; // Вспомогательная переменная для вызова StartService

procedure DriverCreateFile;
procedure DriverCreate;
procedure DriverDestroy;
procedure DriverDirectWrite(Addr: Word; data: Byte);
procedure DriverBitOperation(var TempByte: Byte; BitToSet: TBitSet; Operation: TBitOperation);
procedure SetPortByte(PortAddress: Word; Offset: TOffsetType; data: Byte);

function DriverDirectRead(Addr: Word): Byte;
function DriverIsLoaded: boolean;
function GetPortByte(PortAddress: Word; Offset: TOffsetType): Byte;

function IsPortPresent(LptNumber: Word): boolean;

implementation

procedure DriverCreate;
var
  hSCMahager                            : SC_HANDLE; // Хэндл менеджера сервисов
  hServiceHandle                        : SC_HANDLE; // Хэндл сервиса lptwdmio
  osv                                   : OSVERSIONINFO; // Структура для получения версии платформы

begin

  DriverHandle := INVALID_HANDLE_VALUE;
//  UnregisterService := False;

  if DriverFailedToLoad then Exit;

  osv.dwOSVersionInfoSize := SizeOf(osv);
  GetVersionEx(osv);
  DriverWinNT := (osv.dwPlatformId = VER_PLATFORM_WIN32_NT);

 // Попытка связаться с драйвером
  DriverCreateFile;

  if DriverHandle = INVALID_HANDLE_VALUE then
    if DriverWinNT then
    begin
      hSCMahager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS);
      if 0 <> hSCMahager then
      begin

        hServiceHandle := CreateService(hSCMahager,
          SWC_NAME, // имя сервиса
          SWC_DISPLAY_NAME, // отображаемое имя
          SERVICE_ALL_ACCESS, // права доступа
          SERVICE_KERNEL_DRIVER,
          SERVICE_AUTO_START,
          //SERVICE_DEMAND_START,
          SERVICE_ERROR_NORMAL,
          DRV_BINARY_PATH_NAME,
          nil,
          nil,
          nil,
          nil,
          nil);
        if 0 = hServiceHandle then
        begin // Возможно, сервис был создан ранее
          hServiceHandle := OpenService(hSCMahager, SWC_NAME, SERVICE_ALL_ACCESS); // откроем его
        end;

        if 0 <> hServiceHandle then
        begin // ОК, запускаем сервис
          if not StartService(hServiceHandle, 0, ServiceArgVectors) then // Наш драйвер должен загрузиться...
//            if GetLastError <> ERROR_SERVICE_ALREADY_RUNNING then
          begin
            DriverFailedToLoad := True;

            ShowSysErrorMessage(DRV_BINARY_PATH_NAME);

//            if GetLastError in [ERROR_FILE_NOT_FOUND] then
//              showwarning('To use the parallel port select "tr4wio.sys" component during installation');
          end;

//          UnregisterService := True; // При разрушении объекта не забыть пометить сервис для удаления
          CloseServiceHandle(hServiceHandle); // Освобождаем хэндл
        end;

        CloseServiceHandle(hSCMahager); // Освобождаем хэндл
      end;

   // Вторично пытаемся связаться с драйвером
      DriverCreateFile;
    end;

end;

procedure DriverCreateFile;
begin
  SetLastError(NO_ERROR);
  DriverHandle := CreateFile(DRV_LINK_NAME, GENERIC_READ or GENERIC_WRITE, FILE_SHARE_READ or FILE_SHARE_WRITE, nil, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);
end;

procedure DriverDestroy;
var
  hSCMahager                            : SC_HANDLE;
  hServiceHandle                        : SC_HANDLE;
begin

  if DriverHandle <> INVALID_HANDLE_VALUE then CloseHandle(DriverHandle);
{
  if UnregisterService and DriverWinNT then
  begin // разрегистрировать сервис
    begin
      hSCMahager := OpenSCManager(nil, nil, SC_MANAGER_ALL_ACCESS); // Связаться с менеджером сервисов
      if 0 <> hSCMahager then
      begin
        hServiceHandle := OpenService(hSCMahager, SWC_NAME, SERVICE_ALL_ACCESS); // Получить хэндл сервиса lptwdmio
        if hServiceHandle <> 0 then
        begin
          DeleteService(hServiceHandle); // Пометить сервис как подлежащий удалению. Драйвер останется в памяти до ближайшей перезагрузки.
          CloseServiceHandle(hServiceHandle); // Освобождаем хэндл
        end;
        CloseServiceHandle(hSCMahager); // Высвободить хэндл менеджера сервисов
      end;
    end;
  end;
}
end;

// Возвращает признак готовности/неготовности

function DriverIsLoaded: boolean;
begin
  Result := (DriverHandle <> INVALID_HANDLE_VALUE) or not DriverWinNT; // Либо загружен драйвер, либо Windows 9x
end;

function GetPortByte(PortAddress: Word; Offset: TOffsetType): Byte;
var
  lpBytesReturned                       : DWORD;
  lpOutBuffer                           : Byte;
  TempAddress                           : Word;
begin
  if not DriverIsLoaded() then Exit;
  if DriverHandle <> INVALID_HANDLE_VALUE then
  begin // Чтение через драйвер

    TempAddress := PortAddress + Word(Offset);
    lpBytesReturned := 0;
    DeviceIoControl(DriverHandle,
      IOCTL_READ_PORTS,
      @TempAddress, 2, //InBuffer
      @lpOutBuffer, 1, //OutBuffer
      lpBytesReturned,
      nil);
    Result := lpOutBuffer;
  end
  else
    Result := DriverDirectRead(PortAddress + Word(Offset));
end;

procedure SetPortByte(PortAddress: Word; Offset: TOffsetType; data: Byte);
var
  lpBytesReturned                       : DWORD;
  lpInBuffer                            : Cardinal;
begin
  if Offset = otState then Exit;
  if not DriverIsLoaded() then Exit;
  if DriverHandle <> INVALID_HANDLE_VALUE then
  begin
    lpInBuffer := MakeLong(PortAddress + Word(Offset), data);
    lpBytesReturned := 0;

    DeviceIoControl(DriverHandle,
      IOCTL_WRITE_PORTS,
      @lpInBuffer, 4, //InBuffer
      nil, 0, //OutBuffer
      lpBytesReturned,
      nil);
  end

  else
    DriverDirectWrite(PortAddress + Word(Offset), data);
end;

// Ф-я тестирования наличия порта. Возвратит true, если порт присутствует.

function IsPortPresent(LptNumber: Word): boolean;
var
  data                                  : Byte;
  present                               : boolean;
begin
  present := True;
  data := GetPortByte(LptNumber, otData); // Сохраняем текущее значение регистра данных
  SetPortByte(LptNumber, otData, $00); // Пишем 0
  present := present and ($00 = GetPortByte(LptNumber, otData)); // Проверим -- что записали, то и прочитали?
  SetPortByte(LptNumber, otData, $55); // Пишем $55
  present := present and ($55 = GetPortByte(LptNumber, otData));
  SetPortByte(LptNumber, otData, $AA); // Пишем $AA
  present := present and ($AA = GetPortByte(LptNumber, otData));
  SetPortByte(LptNumber, otData, data); // Восстанавливаем прежнее значение регистра данных
 // Проверим наличие регистров управления и данных, если порт не обнаружен (в случае однонаправленного порта)
  if not present then
  begin
    data := GetPortByte(LptNumber, otControl); // Читаем регистр управления
    present := (data <> $00) and (data <> $FF); // Не пустое значение? -- порт присутствует
    if not present then
    begin
      data := GetPortByte(LptNumber, otState); // Читаем регистр состояния
      present := (data <> $00) and (data <> $FF);
    end;
  end;
  IsPortPresent := present;
end;

// Ф-я тестирования порта на двунаправленность
{
function IsPortBidirectional(LptNumber: Byte): boolean;
var
  data                             : Byte;
  bidir                            : boolean;
begin
  bidir := True;
  data := ReadPort(LptNumber, LPT_CONTROL_REG); // Читаем регистр управления
  WritePort(LptNumber, LPT_CONTROL_REG, data or Direction); // Устанавливаем бит направления (DIR)
  bidir := bidir and (Direction = (Direction and ReadPort(LptNumber, LPT_CONTROL_REG)));
  WritePort(LptNumber, LPT_CONTROL_REG, data and (not Direction)); // Снимаем бит направления (DIR)
  bidir := bidir and (Direction <> (Direction and ReadPort(LptNumber, LPT_CONTROL_REG)));
  WritePort(LptNumber, LPT_CONTROL_REG, data); // Восстанавливаем прежнее значение регистра данных
  IsPortBidirectional := bidir;
end;
}
{ Процедура вывода данных в порт ПК для Windows 9x }

procedure DriverDirectWrite(Addr: Word; data: Byte);
begin
  asm
  push eax
  push edx
  mov dx,Addr
  mov al,Data
  out dx,al
  pop edx
  pop eax
  end;
end;

{ Процедура ввода данных из порта ПК для Windows 9x }

function DriverDirectRead(Addr: Word): Byte;
var
  Value                                 : Byte;
begin
  asm
  push eax
  push edx
  mov dx,Addr
  in al,dx
  mov value,al
  pop edx
  pop eax
  end;
  Result := Value;
end;

procedure DriverBitOperation(var TempByte: Byte; BitToSet: TBitSet; Operation: TBitOperation);
type
  TByteSet = set of 0..SizeOf(Byte) * 8 - 1;
begin
  if Operation = boSet0
    then
//    Exclude(TByteSet(TempByte), integer(BitToSet))
    TempByte := TempByte and not (1 shl Byte(BitToSet))
  else
    TempByte := TempByte or (1 shl Byte(BitToSet));
//    Include(TByteSet(TempByte), integer(BitToSet));
end;

end.

