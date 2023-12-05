page 33001394 "Daily Attendance Worksheet B2B"
{
    // version B2BHR1.00.00

    Caption = 'Daily Attendance Worksheet';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Worksheet;
    SourceTable = "Daily Attendance B2B";
    UsageCategory = Documents;
    ApplicationArea = all;
    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(CurrDate1; CurrDate)
                {
                    Caption = 'Date';
                    ApplicationArea = all;
                    ToolTip = 'Specify the date details';
                    trigger OnLookup(Var Text: Text): Boolean;
                    begin
                        if PAGE.RUNMODAL(0, DailyAttend) = ACTION::LookupOK then
                            CurrDate := DailyAttend.Date;
                        SelectDate();
                    end;

                    trigger OnValidate();

                    begin
                        CurrDateOnAfterValidate();
                    end;
                }
            }
            repeater(Control1102154000)
            {
                field("Employee No."; Rec."Employee No.")
                {
                    Editable = false;
                    ApplicationArea = all;
                    ToolTip = 'Specify the Employee No';
                }
                field("Employee Name"; Rec."Employee Name")
                {
                    Editable = false;
                    ApplicationArea = all;
                    ToolTip = 'Specify the Employee name';
                }
                field("Time In"; Rec."Time In")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specify the Time in details';
                }
                field("Time Out"; Rec."Time Out")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specify the time out details';
                }
                field("Non-Working"; Rec."Non-Working")
                {
                    Editable = false;
                    ApplicationArea = all;
                    ToolTip = 'Specify the Non-working day details';
                }
                field("OT Hrs"; Rec."OT Hrs")
                {
                    Editable = false;
                    ApplicationArea = all;
                    ToolTip = 'Specify the OT Hr details';
                }
                field("OT Approved Hrs"; Rec."OT Approved Hrs")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specify the OT approved Hrs details';
                }
                field("Attendance Type"; Rec."Attendance Type")
                {
                    ApplicationArea = all;
                    ToolTip = 'Specify the attendance type details';
                }
                field("Leave Code"; Rec."Leave Code")
                {
                    Editable = false;
                    ApplicationArea = all;
                    ToolTip = 'Specify the leave code details';
                }
                field(Authorised; Rec.Authorised)
                {
                    Editable = false;
                    ApplicationArea = all;
                    ToolTip = 'Specify the leave authorised user details';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage();
    begin
        CurrDate := 0D;
        SelectDate();
    end;

    var
        DailyAttend: Record "Daily Attendance B2B";
        CurrDate: Date;


    procedure SelectDate();
    begin
        Rec.SETRANGE(Date, CurrDate);
        CurrPage.UPDATE(false);
    end;

    local procedure CurrDateOnAfterValidate();
    begin
        SelectDate();
    end;
}

