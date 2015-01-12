unit uRussiaOblasts;

interface

uses
  Windows {,  CLCUtils};

type

//  CallString = string[CallstringLength];
//  Str2 = string[2];

  ResultRecord = record
    rrIndex: integer;
    rrScore: integer;
  end;

  RegionResultsRecord = record
    rrrNumberOfStations: integer;
    rrrSOResults: Byte;
    rrrMOResults: Byte;
    rrrSOArray: array[1..3] of ResultRecord;
    rrrMOArray: array[1..2] of ResultRecord;
    rrrScore: integer;
  end;

  RussianRegionType =
    (
    rtUnknownRegion,

    rtUA1A,
    rtUA1C,
    rtUA1N,
    rtUA1O,
    rtUA1P,
    rtUA1Q,
    rtUA1T,
    rtUA1W,
    rtUA1Z,

    rtUA2F,

    rtUA3A,
    rtUA3C,
    rtUA3E,
    rtUA3G,
    rtUA3I,
    rtUA3L,
    rtUA3M,
    rtUA3N,
    rtUA3P,
    rtUA3Q,
    rtUA3R,
    rtUA3S,
    rtUA3T,
    rtUA3U,
    rtUA3V,
    rtUA3W,
    rtUA3X,
    rtUA3Y,
    rtUA3Z,

    rtUA4A,
    rtUA4C,
    rtUA4L,
    rtUA4N,
    rtUA4H,
    rtUA4F,
    rtUA4W,
    rtUA4P,
    rtUA4S,
    rtUA4U,
    rtUA4Y,

    rtUA6A,
    rtUA6E,
    rtUA6H,
    rtUA6I,
    rtUA6J,
    rtUA6L,
    rtUA6P,
    rtUA6Q,
    rtUA6U,
    rtUA6W,
    rtUA6X,
    rtUA6Y,

    rtUA9A,
    rtUA9C,
    rtUA9F,
//    rtUA9G,
    rtUA9H,
    rtUA9J,
    rtUA9K,
    rtUA9L,
    rtUA9M,
    rtUA9O,
    rtUA9Q,
    rtUA9S,
    rtUA9U,
    rtUA9W,
    rtUA9X,
    rtUA9Y,
    rtUA9Z,

    rtUA0A,
//    rtUA0B,
    rtUA0C,
    rtUA0D,
    rtUA0F,
//    rtUA0H,
    rtUA0I,
    rtUA0J,
    rtUA0K,
    rtUA0L,
    rtUA0O,
    rtUA0Q,
    rtUA0S,
    rtUA0U,
    rtUA0W,
//    rtUA0X,
    rtUA0Y,
    rtUA0Z

    );

const

  RussianRegionsTypeIdArray             : array[RussianRegionType] of array[0..1] of Char =
    (
    #0#0,

    'SP',
    'LO',
    'KL',
    'AR',
    'NO',
    'VO',
    'NV',
    'PS',
    'MU',

    'KA', //    'Калининградская область (UA2F)',

    'MA', //    'Москва (UA3A)',
    'MO', //    'Московская область (UA3C)',
    'OR', //    'Орловская область (UA3E)',
    'LP', //    'Липецкая область (UA3G)',
    'TV', //    'Тверская область (UA3I)',
    'SM', //    'Смоленская область (UA3L)',
    'YR', //    'Ярославская область (UA3M)',
    'KS', //    'Костромская область (UA3N)',
    'TL', //    'Тульская область (UA3P)',
    'VR', //    'Воронежская область (UA3Q)',
    'TB', //    'Тамбовская область (UA3R)',
    'RA', //    'Рязанская область (UA3S)',
    'NN', //    'Нижегородская область (UA3T)',
    'IV', //    'Ивановская область (UA3U)',
    'VL', //    'Владимирская область (UA3V)',
    'KU', //    'Курская область (UA3W)',
    'KG', //    'Калужская область (UA3X)',
    'BR', //    'Брянская область (UA3Y)',
    'BO', //    'Белгородская область (UA3Z)',

    'VG', //    'Волгоградская область (UA4A)',
    'SA', //    'Саратовская область (UA4C)',
    'UL', //    'Ульяновская область (UA4L)',
    'KI', //    'Кировская область (UA4N)',
    'SR', //    'Самарская область (UA4H)',
    'PE', //    'Пензенская область (UA4F)',
    'UD', //    'Удмуртская Республика (UA4W)',
    'TA', //    'Республика Татарстан (UA4P)',
    'MR', //    'Республика Марий Эл (UA4S)',
    'MD', //    'Республика Мордовия (UA4U)',
    'CU', //    'Чувашская Республика (UA4Y)',

    'KR', //    'Краснодарский край (UA6A)',
    'KC', //    'Карачаево-Черкесская Республика (UA6E)',
    'ST', //    'Ставропольский край (UA6H)',
    'KM', //    'Республика Калмыкия (UA6I)',
    'SO', //    'Республика Северная Осетия - Алания (UA6J)',
    'RO', //    'Ростовская область (UA6L)',
    'CN', //    'Чеченская Республика (UA6P)',
    'IN', //    'Республика Ингушетия (UA6Q)',
    'AO', //    'Астраханская область (UA6U)',
    'DA', //    'Республика Дагестан (UA6W)',
    'KB', //    'Кабардино-Балкарская Республика (UA6X)',
    'AD', //    'Республика Адыгея (UA6Y)',

    'CB', //    'Челябинская область (UA9A)',
    'SV', //    'Свердловская область (UA9C)',
    'PM', //    'Пермский край (UA9F)',
//    'Коми-Пермяцкий округ (UA9G)',
    'TO', //    'Томская область (UA9H)',
    'HM', //    'Ханты-Мансийский автономный округ - Югра (UA9J)',
    'YN', //    'Ямало-Ненецкий автономный округ (UA9K)',
    'TN', //    'Тюменская область (UA9L)',
    'OM', //    'Омская область (UA9M)',
    'NS', //    'Новосибирская область (UA9O)',
    'KN', //    'Курганская область (UA9Q)',
    'OB', //    'Оренбургская область (UA9S)',
    'KE', //    'Кемеровская область (UA9U)',
    'BA', //    'Республика Башкортостан (UA9W)',
    'KO', //    'Республика Коми (UA9X)',
    'AL', //    'Алтайский край (UA9Y)',
    'GA', //    'Республика Алтай (UA9Z)',

    'KK', //    'Красноярский край (UA0A)',
//    '? (UA0B)',
    'HK', //    'Хабаровский край (UA0C)',
    'EA', //    'Еврейская автономная область (UA0D)',
    'SL', //    'Сахалинская область (UA0F)',
//    '? (UA0H)',
    'MG', //    'Магаданская область (UA0I)',
    'AM', //    'Амурская область (UA0J)',
    'CK', //    'Чукотский автономный округ (UA0K)',
    'PK', //    'Приморский край (UA0L)',
    'BU', //    'Республика Бурятия (UA0O)',
    'YA', //    'Республика Саха (Якутия) (UA0Q)',
    'IR', //    'Иркутская область (UA0S)',
    'ZK', //?//    'Забайкальский край (UA0U)',
    'HA', //    'Республика Хакасия (UA0W)',
//    '? (UA0X)',
    'TU', //    'Республика Тыва (UA0Y)',
    'KT' //    'Камчатский край (UA0Z)'
    );

  RussianRegionsTypeStringArray         : array[RussianRegionType] of PChar =
    (
    'rtUnknownRegion',

    'Санкт-Петербург (UA1A)',
    'Ленинградская область (UA1C)',
    'Республика Карелия (UA1N)',
    'Архангельская область (UA1O)',
    'Ненецкий автономный округ (UA1P)',
    'Вологодская область (UA1Q)',
    'Новгородская область (UA1T)',
    'Псковская область (UA1W)',
    'Мурманская область (UA1Z)',

    'Калининградская область (UA2F)',

    'Москва (UA3A)',
    'Московская область (UA3C)',
    'Орловская область (UA3E)',
    'Липецкая область (UA3G)',
    'Тверская область (UA3I)',
    'Смоленская область (UA3L)',
    'Ярославская область (UA3M)',
    'Костромская область (UA3N)',
    'Тульская область (UA3P)',
    'Воронежская область (UA3Q)',
    'Тамбовская область (UA3R)',
    'Рязанская область (UA3S)',
    'Нижегородская область (UA3T)',
    'Ивановская область (UA3U)',
    'Владимирская область (UA3V)',
    'Курская область (UA3W)',
    'Калужская область (UA3X)',
    'Брянская область (UA3Y)',
    'Белгородская область (UA3Z)',

    'Волгоградская область (UA4A)',
    'Саратовская область (UA4C)',
    'Ульяновская область (UA4L)',
    'Кировская область (UA4N)',
    'Самарская область (UA4H)',
    'Пензенская область (UA4F)',
    'Удмуртская Республика (UA4W)',
    'Республика Татарстан (UA4P)',
    'Республика Марий Эл (UA4S)',
    'Республика Мордовия (UA4U)',
    'Чувашская Республика (UA4Y)',

    'Краснодарский край (UA6A)',
    'Карачаево-Черкесская Республика (UA6E)',
    'Ставропольский край (UA6H)',
    'Республика Калмыкия (UA6I)',
    'Республика Северная Осетия - Алания (UA6J)',
    'Ростовская область (UA6L)',
    'Чеченская Республика (UA6P)',
    'Республика Ингушетия (UA6Q)',
    'Астраханская область (UA6U)',
    'Республика Дагестан (UA6W)',
    'Кабардино-Балкарская Республика (UA6X)',
    'Республика Адыгея (UA6Y)',

    'Челябинская область (UA9A)',
    'Свердловская область (UA9C)',
    'Пермский край (UA9F)',
//    'Коми-Пермяцкий округ (UA9G)',
    'Томская область (UA9H)',
    'Ханты-Мансийский автономный округ - Югра (UA9J)',
    'Ямало-Ненецкий автономный округ (UA9K)',
    'Тюменская область (UA9L)',
    'Омская область (UA9M)',
    'Новосибирская область (UA9O)',
    'Курганская область (UA9Q)',
    'Оренбургская область (UA9S)',
    'Кемеровская область (UA9U)',
    'Республика Башкортостан (UA9W)',
    'Республика Коми (UA9X)',
    'Алтайский край (UA9Y)',
    'Республика Алтай (UA9Z)',

    'Красноярский край (UA0A)',
//    '? (UA0B)',
    'Хабаровский край (UA0C)',
    'Еврейская автономная область (UA0D)',
    'Сахалинская область (UA0F)',
//    '? (UA0H)',
    'Магаданская область (UA0I)',
    'Амурская область (UA0J)',
    'Чукотский автономный округ (UA0K)',
    'Приморский край (UA0L)',
    'Республика Бурятия (UA0O)',
    'Республика Саха (Якутия) (UA0Q)',
    'Иркутская область (UA0S)',
    'Забайкальский край (UA0U)',
    'Республика Хакасия (UA0W)',
//    '? (UA0X)',
    'Республика Тыва (UA0Y)',
    'Камчатский край (UA0Z)'
    );
type
  OkrugType =
    (
    foUnKnownOkrug,
    foDalneVostochnyiy,
    foPrivolzhskiy,
    foSeveroZapadniy,
    foSibirskiy,
    foUralskiy,
    foCentralniy,
    foYuzhniy,
    foSeveroKavkazskiy
    );

const

  OkrugTypeStringArray                  : array[OkrugType] of PChar =
    (
    'UnKnownOkrug',
    'Дальневосточный федеральный округ',
    'Приволжский федеральный округ',
    'Северо-Западный федеральный округ',
    'Сибирский федеральный округ',
    'Уральский федеральный округ',
    'Центральный федеральный округ',
    'Южный федеральный округ',
    'Северо-Кавказский федеральный округ'
    );

var
  RegionsResults                        : array[RussianRegionType] of RegionResultsRecord;

//function GetRegion(Callsign: CallString): RegionType;
function GetOkrugByOblast(Oblast: RussianRegionType): OkrugType;
function GetRussiaOblastByTwoChars(c1, c2: Char): RussianRegionType;

implementation

function GetRussiaOblastByTwoChars(c1, c2: Char): RussianRegionType;
begin

  Result := rtUnknownRegion;

  case c1 of

    '1':
      begin
        case c2 of
          'A', 'B', 'F', 'G', 'J', 'L', 'M': Result := rtUA1A;
          'C', 'D': Result := rtUA1C;
          'N': Result := rtUA1N;
          'O': Result := rtUA1O;
          'P': Result := rtUA1P;
          'Q' {, 'R', 'S'}: Result := rtUA1Q;

          'T': Result := rtUA1T;
          'W': Result := rtUA1W;
          'Z': Result := rtUA1Z;

        end;
      end;
{
    '2':
      begin
        case c2 of
          'C', 'F': Result := rtUA2F;
          'D': Result := rtUA3C;
          'S': Result := rtUA3S;
          'T': Result := rtUA3T;
          'U': Result := rtUA3U;
        end;
      end;
}
    '2', '3', '5':
      begin
        case c2 of
          'A', 'B', 'C': Result := rtUA3A;
          'D', 'F', 'H': Result := rtUA3C;

          'E': Result := rtUA3E;
          'G': Result := rtUA3G;
          'I': Result := rtUA3I;
          'L': Result := rtUA3L;
          'M': Result := rtUA3M;
          'N': Result := rtUA3N;
          'P': Result := rtUA3P;
          'K', 'Q', 'O': Result := rtUA3Q;
          'R': Result := rtUA3R;
          'S': Result := rtUA3S;
          'T': Result := rtUA3T;
          'U': Result := rtUA3U;
          'V': Result := rtUA3V;
          'W': Result := rtUA3W;
          'X': Result := rtUA3X;
          'Y': Result := rtUA3Y;
          'Z': Result := rtUA3Z;
        end;
      end;

    '4':
      begin
        case c2 of
          'A', 'B': Result := rtUA4A;
          'C', 'D': Result := rtUA4C;
          'F': Result := rtUA4F;
          'H', 'I': Result := rtUA4H;
          'L', 'M': Result := rtUA4L;
          'N', 'O': Result := rtUA4N;
          'P', 'Q', 'R': Result := rtUA4P;
          'S', 'T': Result := rtUA4S;
          'U': Result := rtUA4U;
          'W': Result := rtUA4W;
          'Y', 'Z': Result := rtUA4Y;

        end;
      end;
{
    '5':
      begin
        case c2 of
          'A': Result := rtUA3A;
          'F': Result := rtUA3C;
          'K', 'Q', 'O': Result := rtUA3Q;
          'Z': Result := rtUA3Z;
        end;
      end;
}
    '7', '6':
      begin
        case c2 of
          'A', 'B', 'C', 'D': Result := rtUA6A;
          'E': Result := rtUA6E;
          'G', 'H', 'F': Result := rtUA6H;
          'I': Result := rtUA6I;
          'J': Result := rtUA6J;
          'L', 'M', 'N', 'O': Result := rtUA6L;
          'P': Result := rtUA6P;
          'Q': Result := rtUA6Q;
          'U', 'V': Result := rtUA6U;
          'W': Result := rtUA6W;
          'X': Result := rtUA6X;
          'Y': Result := rtUA6Y;
        end;
      end;

    '8', '9':
      begin
        case c2 of
          'A', 'B': Result := rtUA9A;
          'C', 'D', 'E': Result := rtUA9C;
          'F': Result := rtUA9F;
//          'G': Result := rtUA9G;
          'H', 'I': Result := rtUA9H;
          'J': Result := rtUA9J;
          'K': Result := rtUA9K;
          'L': Result := rtUA9L;
          'M', 'N': Result := rtUA9M;
          'O', 'P': Result := rtUA9O;
          'Q', 'R': Result := rtUA9Q;
          'S', 'T': Result := rtUA9S;
          'U', 'V': Result := rtUA9U;

          'W': Result := rtUA9W;
          'X': Result := rtUA9X;
          'Y': Result := rtUA9Y;

          'Z': Result := rtUA9Z;
        end;
      end;

    '0':
      begin
        case c2 of
          'A', 'B', 'H': Result := rtUA0A;
//          'B': Result := rtUA0B;
          'C': Result := rtUA0C;
          'D': Result := rtUA0D;
          'F', 'E': Result := rtUA0F;
//          'H': Result := rtUA0H;
          'I': Result := rtUA0I;
          'J': Result := rtUA0J;
          'K': Result := rtUA0K;
          'L', 'M', 'N': Result := rtUA0L;
          'O': Result := rtUA0O;
          'Q': Result := rtUA0Q;
          'R', 'S', 'T': Result := rtUA0S;

          'U', 'V': Result := rtUA0U;
          'W': Result := rtUA0W;
//          'X': Result := rtUA0X;
          'Y': Result := rtUA0Y;
          'Z', 'X': Result := rtUA0Z;
        end;
      end;
  end;

  if c1 = '2' then
    if c2 in ['F', 'K', 'C'] then
      Result := rtUA2F;

end;
{
function GetRegion(Callsign: CallString): RegionType;
var
  TwoChars                              : Str2;
begin
  Result := rtUnknownRegion;
  TwoChars := GetOblast(Callsign);
  if length(TwoChars) <> 2 then Exit;
  Result := GetRussiaOblastByTwoChars(TwoChars[1], TwoChars[2]);
end;
}
{
procedure MakeRegionsList;
var
  c1, c2                                : Char;
  TempCallsign                          : CallString;
  ResultRegion, TempRegion              : RegionType;
  h                                     : HWND;
  TempBuffer                            : array[0..255] of Char;
begin

  h := CreateFile('regions.txt', GENERIC_WRITE, FILE_SHARE_WRITE, nil, CREATE_ALWAYS, FILE_ATTRIBUTE_ARCHIVE, 0);

  for TempRegion := Low(RegionType) to High(RegionType) do
  begin

    if TempRegion = rtUnknownRegion then Continue;

    Format(TempBuffer, '%3u %-50s: ', integer(TempRegion), RegionTypeStringArray[TempRegion]);
    sWriteFile(h, TempBuffer);
    for c1 := '0' to '9' do
      for c2 := 'A' to 'Z' do
      begin
        Windows.ZeroMemory(@TempCallsign, SizeOf(TempCallsign));
        TempCallsign[0] := CHR(4);
        TempCallsign[1] := 'U';
        TempCallsign[2] := 'A';
        TempCallsign[3] := c1;
        TempCallsign[4] := c2;

        ResultRegion := GetRegion(TempCallsign);

        if ResultRegion = TempRegion then
        begin
          Format(TempBuffer, ' %s', @TempCallsign[1]);
          sWriteFile(h, TempBuffer);
        end;
      end;

    sWriteFile(h, #13#10);
  end;

  CloseHandle(h);

end;
}

function GetOkrugByOblast(Oblast: RussianRegionType): OkrugType;
begin

  Result := foUnKnownOkrug;

  case Oblast of
    rtUA3Z,
      rtUA3Y,
      rtUA3V,
      rtUA3Q,
      rtUA3U,
      rtUA3X,
      rtUA3N,
      rtUA3W,
      rtUA3G,
      rtUA3C,
      rtUA3E,
      rtUA3S,
      rtUA3L,
      rtUA3R,
      rtUA3I,
      rtUA3P,
      rtUA3M,
      rtUA3A: Result := foCentralniy;

    rtUA6Y,
      rtUA6I,
      rtUA6A,
      rtUA6U,
      rtUA4A,
      rtUA6L: Result := foYuzhniy;

    rtUA1N,
      rtUA9X,
      rtUA1O,
      rtUA1Q,
      rtUA2F,
      rtUA1C,
      rtUA1Z,
      rtUA1T,
      rtUA1W,
      rtUA1A,
      rtUA1P: Result := foSeveroZapadniy;

    rtUA0Q,
      rtUA0Z,
      rtUA0L,
      rtUA0C,
      rtUA0J,
      rtUA0I,
      rtUA0F,
      rtUA0D,
      rtUA0K: Result := foDalneVostochnyiy;

    rtUA9Z,
      rtUA0O,
      rtUA0Y,
      rtUA0W,
      rtUA9Y,
      rtUA0U,
      rtUA0A,
      rtUA0S,
      rtUA9U,
      rtUA9O,
      rtUA9M,
      rtUA9H: Result := foSibirskiy;

    rtUA9Q,
      rtUA9C,
      rtUA9L,
      rtUA9A,
      rtUA9J,
      rtUA9K: Result := foUralskiy;

    rtUA9W,
      rtUA4S,
      rtUA4U,
      rtUA4P,
      rtUA4W,
      rtUA4Y,
      rtUA9F,
      rtUA4N,
      rtUA3T,
      rtUA9S,
      rtUA4F,
      rtUA4H,
      rtUA4C,
      rtUA4L: Result := foPrivolzhskiy;

    rtUA6W,
      rtUA6Q,
      rtUA6X,
      rtUA6E,
      rtUA6J,
      rtUA6P,
      rtUA6H: Result := foSeveroKavkazskiy;
  end;

end;

begin
//  MakeRegionsList;
end.

