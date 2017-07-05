{ Demonstrates FreeNotication to safely link to controls in other forms
  through form linking and demonstrates preventing a component from being used
  in form inheritance }

unit DemoLbl;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs;

type
  TDemoLabel = class(TGraphicControl)
  private
    FFocusControl: TWinControl;
    procedure SetFocusControl(Value: TWinControl);
    procedure CMDialogChar(var Message: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Caption;
    property Color;
    property FocusControl: TWinControl read FFocusControl write SetFocusControl;
    property Font;
    property ParentColor;
    property ParentFont;
  end;

procedure Register;

implementation

{ TDemoLabel }

constructor TDemoLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FComponentStyle := FComponentStyle - [csInheritable];
end;

procedure TDemoLabel.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if (Operation = opRemove) and (AComponent = FFocusControl) then
    FFocusControl := nil;
end;

procedure TDemoLabel.SetFocusControl(Value: TWinControl);
begin
  FFocusControl := Value;

  { Calling FreeNotification ensures that this component will receive an
    opRemove when Value is either removed from its owner or when it is
    destroyed. }

  Value.FreeNotification(Self);
end;

procedure TDemoLabel.Paint;
var
  Rect: TRect;
begiN
  Rect := ClientRect;
  Canvas.Font := Font;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(Rect);
  DrawText(Canvas.Handle, PChar(Caption), Length(Caption), Rect,
    DT_EXPANDTABS or DT_WORDBREAK or DT_LEFT);
end;

procedure TDemoLabel.CMDialogChar(var Message: TCMDialogChar);
begin
  if (FFocusControl <> nil) and Enabled and
    IsAccel(Message.CharCode, Caption) then
    with FFocusControl do
      if CanFocus then
      begin
        SetFocus;
        Message.Result := 1;
      end;
end;

procedure TDemoLabel.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure Register;
begin
  RegisterComponents('Samples', [TDemoLabel]);
end;

end.
