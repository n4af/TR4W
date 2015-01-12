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
unit LPTIO;

interface
uses
  VC,
  Windows;

const
   { Имя символuческой связи }
  DRV_LINK_NAME                         : string = '\\.\LptAccessAgent';

   { Коды сообщений драйверу }
  IOCTL_READ_PORTS                      : Cardinal = $00220050; // Чтение регистров LPT
  IOCTL_WRITE_PORTS                     : Cardinal = $00220060; // Запись в регистры LPT

   { Номера портов LPT }
  LPT1                                  : Byte = $10; // база $3BC
  LPT2                                  : Byte = $20; //      $378
  LPT3                                  : Byte = $30; //      $278

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
  SC_MANAGER_ALL_ACCESS                 : Cardinal = $000F003F;
  SERVICE_ALL_ACCESS                    : Cardinal = $000F01FF;

  SWC_NAME                              : string = 'lptwdmio'; { Системное имя сервиса }
  SWC_DISPLAY_NAME                      : string = 'LPT port direct access service'; { Название сервиса, чтобы показать пользователю :) }

type
   { Структура Адрес-Данные }
  ADRDATASTRUCT = record
    Adr: Byte; { адрес == <Номер порта> or <Смещение регистра>      }
    data: Byte; { данные для вывода или место для прочитанного байта }
  end;
  PADRDATASTRUCT = ^ADRDATASTRUCT;

   { Типы для обращения к менеджеру сервисов NT }
  SC_HANDLE = Cardinal; // Тип хэндла для обращения к менеджеру сервисов

   { Процедурный тип для обращения к ф-и OpenSCManager }
  POpenSCManager = function(lpMachineName, lpDatabaseName: PChar;
    dwDesiredAccess: DWORD): SC_HANDLE; stdcall;

   { Процедурный тип для обращения к ф-и CloseServiceHandle }
  PCloseServiceHandle = function(hSCObject: SC_HANDLE): BOOL; stdcall;

   { Процедурный тип для обращения к ф-и CreateService }
  PCreateService = function(hSCManager: SC_HANDLE;
    lpServiceName, lpDisplayName: PChar;
    dwDesiredAccess, dwServiceType, dwStartType, dwErrorControl: DWORD;
    lpBinaryPathName, lpLoadOrderGroup: PChar;
    lpdwTagId: LPDWORD;
    lpDependencies, lpServiceStartName, lpPassword: PChar): SC_HANDLE; stdcall;

   { Процедурный тип для обращения к ф-и StartService }
  PStartService = function(hService: SC_HANDLE; dwNumServiceArgs: DWORD;
    var lpServiceArgVectors: PChar): BOOL; stdcall;

   { Процедурный тип для обращения к ф-и OpenService }
  POpenService = function(hSCManager: SC_HANDLE; lpServiceName: PChar;
    dwDesiredAccess: DWORD): SC_HANDLE; stdcall;

   { Процедурный тип для обращения к ф-и DeleteService }
  PDeleteService = function(hService: SC_HANDLE): BOOL; stdcall;

   { Класс для обращения к драйверу LPTWDMIO.sys }
  TLptPortConnection = class
  private
    hdrv: Cardinal; // Хэндл загруженного драйвера
    winnt: boolean; // Признак платформы NT

      { Данные, относящиеся к вызову менеджера сервисов на платформах NT }
    UnregisterService: boolean; // флаг, показывающий необходимость удаления сервиса lptwdmio по закрытии приложения в Win NT
    hdll: Cardinal; // Хэндл библиотеки advapi32.dll
    SysBinaryName: AnsiString; // Имя файла драйвера
    ServiceArgVectors: PChar; // Вспомогательная переменная для вызова StartService
    OpenSCManager_: POpenSCManager; // Указатель на ф-ю OpenSCManager Win32 API
    CloseServiceHandle_: PCloseServiceHandle; // -//- CloseServiceHandle
    CreateService_: PCreateService; // -//- CreateService
    StartService_: PStartService; // -//- StartService
    OpenService_: POpenService; // -//- OpenService
    DeleteService_: PDeleteService; // -//- DeleteService

      // Флаги наличия портов
    PortPresent: array[0..2] of boolean;

      { Процедура вывода данных в порт ПК для Windows 9x }
    procedure Writepk(Addr: Word; data: Byte);

      { Процедура ввода данных из порта ПК для Windows 9x }
    function Readpk(Addr: Word): Byte;

  public
    constructor Create; // Конструктор
    destructor Destroy; override; // Деструктор

    function Ready: boolean; // Возвращает признак готовности/неготовности

      // Ф-я возвращает true, если работаем на платформе NT
    function IsNtPlatform: boolean;

      // Ф-я тестирования наличия порта. Возвратит true, если порт присутствует.
    function IsPortPresent(LptNumber: Byte): boolean;

      // Ф-я тестирования порта на двунаправленность
    function IsPortBidirectional(LptNumber: Byte): boolean;

      // Функция для чтения регистров LPT. Возвращает true, если чтение прошло успешно.
      // PairArray -- массив структур ADRDATASTRUCT, в которые будут считываться данные из портов.
      //  Члены Adr должны быть инициализированы значениями (<Номер порта LPT>or<Смещение регистра>),
      //  например: PairArray[i].Adr := LPT1 or LPT_STATE_REG;
      //
      // PairCount -- количество структур в массиве PairArray.
    function ReadPorts(PairArray: PADRDATASTRUCT; PairCount: Cardinal): boolean;

      // Функция для вывода данных в регистры LPT. Возвращает true, если запись прошла успешно.
      // PairArray -- см. выше, + члены Data структур ADRDATASTRUCT должны содержать данные для вывода
      //  в соответствующие регистры порта.
      // PairCount -- см. выше.
    function WritePorts(PairArray: PADRDATASTRUCT; PairCount: Cardinal): boolean;

      // Функция для чтения одного регистра указанного порта
    function ReadPort(LptNumber: Byte; RegOffset: Byte): Byte;

      // Процедура для вывода значения в регистр порта
    procedure WritePort(LptNumber: Byte; RegOffset: Byte; Value: Byte);

      // Процедура для выполнения задержки
      // Time -- величина задержки в мкс. Допустимые значения - от 0 до 50 мкс.
    procedure Delay(Time: Cardinal);

  end; {class}
  PLptPortConnection = ^TLptPortConnection;

implementation
uses Unit1;

// Конструктор

constructor TLptPortConnection.Create;
var
  osv                                   : OSVERSIONINFO; // Структура для получения версии платформы
  hSCMahager                            : SC_HANDLE; // Хэндл менеджера сервисов
  hServiceHandle                        : SC_HANDLE; // Хэндл сервиса lptwdmio
begin
  inherited Create;
   // Первичная инициализация
  hdrv := INVALID_HANDLE_VALUE;
  UnregisterService := False;
  hdll := 0;

   // Узнаем версию ОС
  osv.dwOSVersionInfoSize := SizeOf(osv);
  GetVersionex(osv);
  winnt := (osv.dwPlatformId = VER_PLATFORM_WIN32_NT); // NT-я или нет?

   // Попытка связаться с драйвером
  SetLastError(NO_ERROR);

  if winnt then //wli
    hdrv := CreateFile(PChar(DRV_LINK_NAME),
      GENERIC_READ or GENERIC_WRITE,
      FILE_SHARE_READ or FILE_SHARE_WRITE,
      nil,
      OPEN_EXISTING,
      FILE_ATTRIBUTE_NORMAL,
      0);

  if hdrv = INVALID_HANDLE_VALUE then
    if winnt then // Не удалось связаться с драйвером. Он не был установлен вручную.
    begin
            // Windows NT -- пробуем запустить драйвер через менеджер управления сервисами
      hdll := LoadLibrary(PChar('ADVAPI32.DLL')); // Получим указатели на ф-и менеджера сервисов.
      if hdll <> 0 then
      begin
                  // Re: чтобы программа работала и на NT, и на 9x, используем динамическую загрузку AdvApi32.dll
                   // Получим указатели на ф-и в AdvApi32.dll
        OpenSCManager_ := POpenSCManager(GetProcAddress(hdll, PChar('OpenSCManagerA')));
        CloseServiceHandle_ := PCloseServiceHandle(GetProcAddress(hdll, PChar('CloseServiceHandle')));
        CreateService_ := PCreateService(GetProcAddress(hdll, PChar('CreateServiceA')));
        StartService_ := PStartService(GetProcAddress(hdll, PChar('StartServiceA')));
        OpenService_ := POpenService(GetProcAddress(hdll, PChar('OpenServiceA')));
        DeleteService_ := PDeleteService(GetProcAddress(hdll, PChar('DeleteService')));

                  // Свяжемся с менеджером сервисов
        hSCMahager := OpenSCManager_(nil, nil, SC_MANAGER_ALL_ACCESS);
        if 0 <> hSCMahager then
        begin // Связались успешно
          SysBinaryName := TR4W_PATH_NAME + 'LPTWDMIO.SYS'; // имя бинарника sys
                        // Попытка создания сервиса
          hServiceHandle := CreateService_(hSCMahager,
            PChar(SWC_NAME), // имя сервиса
            PChar(SWC_DISPLAY_NAME), // отображаемое имя
            SERVICE_ALL_ACCESS, // права доступа
            1, // SERVICE_KERNEL_DRIVER
            3, // SERVICE_DEMAND_START
            1, // SERVICE_ERROR_NORMAL
            PChar(SysBinaryName),
            nil,
            nil,
            nil,
            nil,
            nil);
          if 0 = hServiceHandle then
          begin // Возможно, сервис был создан ранее
            hServiceHandle := OpenService_(hSCMahager, PChar(SWC_NAME), SERVICE_ALL_ACCESS); // откроем его
          end;
          if 0 <> hServiceHandle then
          begin // ОК, запускаем сервис
            ServiceArgVectors := nil;
            StartService_(hServiceHandle, 0, ServiceArgVectors); // Наш драйвер должен загрузиться...
            UnregisterService := True; // При разрушении объекта не забыть пометить сервис для удаления
            CloseServiceHandle_(hServiceHandle); // Освобождаем хэндл
          end;

          CloseServiceHandle_(hSCMahager); // Освобождаем хэндл
        end;
      end;

            // Вторично пытаемся связаться с драйвером
      SetLastError(NO_ERROR);
      hdrv := CreateFile(PChar(DRV_LINK_NAME),
        GENERIC_READ or GENERIC_WRITE,
        FILE_SHARE_READ or FILE_SHARE_WRITE,
        nil,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        0);
    end;

  if Ready() then
  begin
         // Определим порты, представленные в системе
    PortPresent[0] := IsPortPresent(LPT1);
    PortPresent[1] := IsPortPresent(LPT2);
    PortPresent[2] := IsPortPresent(LPT3);
  end;
end;

// Деструктор

destructor TLptPortConnection.Destroy;
var
  hSCMahager                            : SC_HANDLE;
  hServiceHandle                        : SC_HANDLE;
begin
  if hdrv <> INVALID_HANDLE_VALUE then CloseHandle(hdrv);
  if UnregisterService and winnt then
  begin // разрегистрировать сервис
    if hdll <> 0 then
    begin
      hSCMahager := OpenSCManager_(nil, nil, SC_MANAGER_ALL_ACCESS); // Связаться с менеджером сервисов
      if 0 <> hSCMahager then
      begin
        hServiceHandle := OpenService_(hSCMahager, PChar(SWC_NAME), SERVICE_ALL_ACCESS); // Получить хэндл сервиса lptwdmio
        if hServiceHandle <> 0 then
        begin
          DeleteService_(hServiceHandle); // Пометить сервис как подлежащий удалению. Драйвер останется в памяти до ближайшей перезагрузки.
          CloseServiceHandle_(hServiceHandle); // Освобождаем хэндл
        end;
        CloseServiceHandle_(hSCMahager); // Высвободить хэндл менеджера сервисов
      end;
      FreeLibrary(hdll); // Высвободить хэндл библиотеки AdvApi32.dll
    end;
  end;
  inherited Destroy;
end;

// Возвращает признак готовности/неготовности

function TLptPortConnection.Ready: boolean;
begin
  Ready := (hdrv <> INVALID_HANDLE_VALUE) or not winnt; // Либо загружен драйвер, либо Windows 9x
end;

// Функция для чтения регистров LPT. Возвращает true, если чтение прошло успешно.

function TLptPortConnection.ReadPorts(PairArray: PADRDATASTRUCT; PairCount: Cardinal): boolean;
var
  cb                                    : Cardinal;
  Pair                                  : PADRDATASTRUCT;
  ct                                    : Cardinal;
  Adr                                   : Word;
begin
  if Ready() then
  begin
    if hdrv <> INVALID_HANDLE_VALUE then
    begin // Чтение через драйвер
      cb := 0;
      SetLastError(NO_ERROR);
      DeviceIoControl(hdrv, IOCTL_READ_PORTS, PairArray, PairCount * 2, PairArray, PairCount * 2, cb, nil);
      ReadPorts := (NO_ERROR = getlasterror());
    end
    else
    begin // Чтение напрямую через обращения к портам (Windows 9x)
      Pair := PairArray;
      for ct := 0 to PairCount - 1 do
      begin // Цикл по переданным структурам
        Adr := $278; // LPT3 по умолчанию
        case (Pair.Adr shr 4) of
          1: Adr := $3BC; // LPT1
          2: Adr := $378; // LPT2
        end; // case
        Adr := Adr + (7 and Pair.Adr); // База + смещение
        Pair.data := Readpk(Adr); // Читать данные
        inc(Pair);
      end; // for
      ReadPorts := True;
    end;
  end else
  begin
    ReadPorts := False;
  end;
end;

// Функция для вывода данных в регистры LPT. Возвращает true, если запись прошла успешно.

function TLptPortConnection.WritePorts(PairArray: PADRDATASTRUCT; PairCount: Cardinal): boolean;
var
  cb                                    : Cardinal;
  Pair                                  : PADRDATASTRUCT;
  ct                                    : Cardinal;
  Adr                                   : Word;
begin
  if Ready() then
  begin
    if hdrv <> INVALID_HANDLE_VALUE then
    begin // Запись через драйвер
      cb := 0;
      SetLastError(NO_ERROR);
      DeviceIoControl(hdrv, IOCTL_WRITE_PORTS, PairArray, PairCount * 2, PairArray, PairCount * 2, cb, nil);
      WritePorts := (NO_ERROR = getlasterror());
    end else
    begin // Запись через прямые обращения к портам (Windows 9x)
      Pair := PairArray;
      for ct := 0 to PairCount - 1 do
      begin // Цикл по переданным структурам
        Adr := $278; // LPT3 по умолчанию
        case (Pair.Adr shr 4) of
          1: Adr := $3BC; // LPT1
          2: Adr := $378; // LPT2
        end; // case
        Adr := Adr + (7 and Pair.Adr); // База + смещение
        Writepk(Adr, Pair.data); // Вывести данные
        inc(Pair);
      end; // for
      WritePorts := True;
    end;
  end else
  begin
    WritePorts := False;
  end;
end;

// Функция для чтения одного регистра указанного порта

function TLptPortConnection.ReadPort(LptNumber: Byte; RegOffset: Byte): Byte;
var
  Pair                                  : ADRDATASTRUCT;
begin
  Pair.Adr := LptNumber or RegOffset;
  Pair.data := 0;
  ReadPorts(@Pair, 1);
  ReadPort := Pair.data;
end;

// Процедура для вывода значения в регистр порта

procedure TLptPortConnection.WritePort(LptNumber: Byte; RegOffset: Byte; Value: Byte);
var
  Pair                                  : ADRDATASTRUCT;
begin
  Pair.Adr := LptNumber or RegOffset;
  Pair.data := Value;
  WritePorts(@Pair, 1);
end;

function TLptPortConnection.IsNtPlatform: boolean;
begin
  IsNtPlatform := winnt;
end;

// Ф-я тестирования наличия порта. Возвратит true, если порт присутствует.

function TLptPortConnection.IsPortPresent(LptNumber: Byte): boolean;
var
  data                                  : Byte;
  present                               : boolean;
begin
  present := True;
  data := ReadPort(LptNumber, LPT_DATA_REG); // Сохраняем текущее значение регистра данных
  WritePort(LptNumber, LPT_DATA_REG, $00); // Пишем 0
  present := present and ($00 = ReadPort(LptNumber, LPT_DATA_REG)); // Проверим -- что записали, то и прочитали?
  WritePort(LptNumber, LPT_DATA_REG, $55); // Пишем $55
  present := present and ($55 = ReadPort(LptNumber, LPT_DATA_REG));
  WritePort(LptNumber, LPT_DATA_REG, $AA); // Пишем $AA
  present := present and ($AA = ReadPort(LptNumber, LPT_DATA_REG));
  WritePort(LptNumber, LPT_DATA_REG, data); // Восстанавливаем прежнее значение регистра данных
   // Проверим наличие регистров управления и данных, если порт не обнаружен (в случае однонаправленного порта)
  if not present then
  begin
    data := ReadPort(LptNumber, LPT_CONTROL_REG); // Читаем регистр управления
    present := (data <> $00) and (data <> $FF); // Не пустое значение? -- порт присутствует
    if not present then
    begin
      data := ReadPort(LptNumber, LPT_STATE_REG); // Читаем регистр состояния
      present := (data <> $00) and (data <> $FF);
    end;
  end;
  IsPortPresent := present;
end;

// Ф-я тестирования порта на двунаправленность

function TLptPortConnection.IsPortBidirectional(LptNumber: Byte): boolean;
var
  data                                  : Byte;
  bidir                                 : boolean;
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

{ Процедура вывода данных в порт ПК для Windows 9x }

procedure TLptPortConnection.Writepk(Addr: Word; data: Byte);
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

function TLptPortConnection.Readpk(Addr: Word): Byte;
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
  Readpk := Value;
end;

// Процедура для выполнения задержки
// Time -- величина задержки в мкс. Допустимые значения - от 0 до 50 мкс.

procedure TLptPortConnection.Delay(Time: Cardinal);
var
  ct                                    : Cardinal;
  ADS                                   : ADRDATASTRUCT;
begin
  ct := Time;
  if (ct > 50) then ct := 50;
  ct := (ct + ct + ct) shr 1; // *1.5, ибо одно чтение из порта -- это примерно 0.6 .. 1.2 мкс на большинстве машин,  независимо от частоты пня и сист. шины.
  if (ct = 0) then ct := 1;
  if (PortPresent[0]) then // выбираем порт, из которого будем читать
  begin
    ADS.Adr := LPT1 or LPT_DATA_REG;
  end else
  begin
    if (PortPresent[1]) then
    begin
      ADS.Adr := LPT2 or LPT_DATA_REG;
    end else
    begin
      ADS.Adr := LPT3 or LPT_DATA_REG;
    end;
  end;
  while ct <> 0 do
  begin
    ReadPorts(@ADS, 1);
    Dec(ct);
  end;
end;

end.
