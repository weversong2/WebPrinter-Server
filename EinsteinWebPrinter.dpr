program EinsteinWebPrinter;

uses
  Vcl.Forms,
  principal in '..\Einstein WebPrinter\principal.pas' {Form1};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Einstein WebPrinter';
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
