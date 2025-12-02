unit Unit2;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

type
  TForm2 = class(TForm)
    Button1: TButton;
    Memo1: TMemo;
    procedure Button1Click(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form2: TForm2;

implementation
 uses MainUnit;
{$R *.dfm}

procedure TForm2.Button1Click(Sender: TObject);
begin
   memo1.Lines.Add('Hello' + TimeToStr(Now));
end;

procedure TForm2.FormDestroy(Sender: TObject);
begin
if form2 <> nil then
   begin
   logger.debug('No nil');
   end;
end;

end.
