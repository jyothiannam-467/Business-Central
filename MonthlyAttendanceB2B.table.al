table 33001218 "Monthly Attendance B2B"
{
    // version B2BHR1.00.00

    Caption = 'Monthly Attendance';
    DrillDownPageID = "Employee Payment Details B2B";
    LookupPageID = "Monthly Attendance List B2B";
    DataClassification = CustomerContent;
    fields
    {
        field(2; "Employee Code"; Code[20])
        {
            Caption = 'Employee Code';
            TableRelation = "Employee B2B";
            DataClassification = CustomerContent;
        }
        field(3; Attendance; Decimal)
        {
            CalcFormula = Sum("Daily Attendance B2B".Present WHERE("Employee No." = FIELD("Employee Code"),
                                                                Year = FIELD(Year),
                                                                Month = FIELD("Pay Slip Month"),
                                                                Present = FILTER(<> 0)));
            Caption = 'Attendance';
            FieldClass = FlowField;
        }
        field(4; Days; Integer)
        {
            CalcFormula = Count("Daily Attendance B2B" WHERE("Employee No." = FIELD("Employee Code"),
                                                          Year = FIELD(Year),
                                                          Month = FIELD("Pay Slip Month")));
            Caption = 'Days';
            FieldClass = FlowField;
        }
        field(5; "Pay Slip Month"; Integer)
        {
            Caption = 'Pay Slip Month';
            ValuesAllowed = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12;
            DataClassification = CustomerContent;
        }
        field(6; "Weekly Off"; Decimal)
        {
            CalcFormula = Sum("Daily Attendance B2B".WeeklyOff WHERE("Employee No." = FIELD("Employee Code"),
                                                                  Year = FIELD(Year),
                                                                  Month = FIELD("Pay Slip Month"),
                                                                  WeeklyOff = FILTER(<> 0)));
            Caption = 'Weekly Off';
            FieldClass = FlowField;
        }
        field(11; "Over Time Hrs"; Decimal)
        {
            CalcFormula = Sum("Daily Attendance B2B"."OT Approved Hrs" WHERE("Employee No." = FIELD("Employee Code"),
                                                                          Year = FIELD(Year),
                                                                          Month = FIELD("Pay Slip Month"),
                                                                          "OT Approved Hrs" = FILTER(<> 0)));
            Caption = 'Over Time Hrs';
            FieldClass = FlowField;
        }
        field(12; "Late Hours"; Decimal)
        {
            CalcFormula = Sum("Daily Attendance B2B"."Late Hrs" WHERE("Employee No." = FIELD("Employee Code"),
                                                                   Year = FIELD(Year),
                                                                   Month = FIELD("Pay Slip Month"),
                                                                   "Late Hrs" = FILTER(<> 0)));
            Caption = 'Late Hours';
            FieldClass = FlowField;
        }
        field(14; Holidays; Decimal)
        {
            CalcFormula = Sum("Daily Attendance B2B".Holiday WHERE("Employee No." = FIELD("Employee Code"),
                                                                Year = FIELD(Year),
                                                                Month = FIELD("Pay Slip Month"),
                                                                Holiday = FILTER(<> 0)));
            Caption = 'Holidays';
            FieldClass = FlowField;
        }
        field(15; "Loss Of Pay"; Decimal)
        {
            CalcFormula = Sum("Daily Attendance B2B".Absent WHERE("Employee No." = FIELD("Employee Code"),
                                                               Year = FIELD(Year),
                                                               Month = FIELD("Pay Slip Month"),
                                                               Absent = FILTER(<> 0)));
            Caption = 'Loss Of Pay';
            FieldClass = FlowField;
        }
        field(17; Year; Integer)
        {
            Caption = 'Year';
            DataClassification = CustomerContent;
        }
        field(18; Process; Boolean)
        {
            Caption = 'Process';
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                if Processed = true then
                    ERROR(Text001Lbl);
            end;
        }
        field(19; Processed; Boolean)
        {
            Caption = 'Processed';
            Editable = true;
            DataClassification = CustomerContent;
        }
        field(20; Posted; Boolean)
        {
            Caption = 'Posted';
            Editable = true;
            DataClassification = CustomerContent;
        }
        field(21; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            DataClassification = CustomerContent;
        }
        field(22; "Processing Date"; Date)
        {
            Caption = 'Processing Date';
            DataClassification = CustomerContent;
        }
        field(23; "Gross Salary"; Decimal)
        {
            CalcFormula = Sum("Processed Salary B2B"."Earned Amount" WHERE("Employee Code" = FIELD("Employee Code"),
                                                                        Year = FIELD(Year),
                                                                        "Pay Slip Month" = FIELD("Pay Slip Month"),
                                                                        "Add/Deduct" = CONST(Addition),
                                                                        "Earned Amount" = FILTER(<> 0)));
            Caption = 'Computed Gross Salary';
            DecimalPlaces = 2 : 2;
            FieldClass = FlowField;
        }
        field(24; Deductions; Decimal)
        {
            CalcFormula = Sum("Processed Salary B2B"."Earned Amount" WHERE("Employee Code" = FIELD("Employee Code"),
                                                                        Year = FIELD(Year),
                                                                        "Pay Slip Month" = FIELD("Pay Slip Month"),
                                                                        "Add/Deduct" = CONST(Deduction),
                                                                        "Add/Deduct Code" = FILTER('<> EMP. ESI&<>EMP. PF'),
                                                                        "Earned Amount" = FILTER(<> 0)));
            Caption = 'Deductions';
            DecimalPlaces = 2 : 2;
            FieldClass = FlowField;
        }
        field(25; "Net Salary"; Decimal)
        {
            Caption = 'Net Salary';
            DecimalPlaces = 2 : 2;
            DataClassification = CustomerContent;
        }
        field(26; "Employee Name"; Text[120])
        {
            Caption = 'Employee Name';
            DataClassification = CustomerContent;
        }
        field(27; Leaves; Decimal)
        {
            CalcFormula = Sum("Daily Attendance B2B".Leave WHERE("Employee No." = FIELD("Employee Code"),
                                                              Year = FIELD(Year),
                                                              Month = FIELD("Pay Slip Month"),
                                                              Leave = FILTER(<> 0)));
            Caption = 'Leaves';
            FieldClass = FlowField;
        }
        field(28; "Co. Contributions"; Decimal)
        {
            CalcFormula = Sum("Temp Processed Salary B2B"."Earned Amount" WHERE("Employee Code" = FIELD("Employee Code"),
                                                                             Year = FIELD(Year),
                                                                             "Pay Slip Month" = FIELD("Pay Slip Month"),
                                                                             "Add/Deduct" = filter('3')));
            Caption = 'Co. Contributions';
            FieldClass = FlowField;
        }
        field(29; "Emp Deduction"; Decimal)
        {
            CalcFormula = Sum("Temp Processed Salary B2B"."Earned Amount" WHERE("Employee Code" = FIELD("Employee Code"),
                                                                             Year = FIELD(Year),
                                                                             "Pay Slip Month" = FIELD("Pay Slip Month"),
                                                                             "Add/Deduct" = CONST(Deduction),
                                                                             "Add/Deduct Code" = FILTER('EMP. ESI|EMP. PF')));
            Caption = 'Emp Deduction';
            FieldClass = FlowField;
        }
        field(30; "Period Start Date"; Date)
        {
            Caption = 'Period Start Date';
            DataClassification = CustomerContent;
        }
        field(31; "Period End Date"; Date)
        {
            Caption = 'Period End Date';
            DataClassification = CustomerContent;
        }
        field(32; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            DataClassification = CustomerContent;
        }
        field(33; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            DataClassification = CustomerContent;
        }
        field(34; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            DataClassification = CustomerContent;
        }
        field(35; PayCadre; Code[30])
        {
            Caption = 'PayCadre';
            DataClassification = CustomerContent;
        }
        field(36; "Paid Amount"; Decimal)
        {
            CalcFormula = Sum("Posted Salary Details B2B"."Salary Paid" WHERE("Employee Code" = FIELD("Employee Code"),
                                                                           Month = FIELD("Pay Slip Month"),
                                                                           Year = FIELD(Year)));
            Caption = 'Paid Amount';
            FieldClass = FlowField;
        }
        field(37; "Remaining Amount"; Decimal)
        {
            Caption = 'Remaining Amount';
            DataClassification = CustomerContent;
        }
        field(42; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                ValidateShortcutDimCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(43; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(2));
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                ValidateShortcutDimCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(45; "Line No."; Integer)
        {
            Caption = 'Line No.';
            DataClassification = CustomerContent;
        }
        field(46; "Cumulative Balance"; Decimal)
        {
            Caption = 'Cumulative Balance';
            DataClassification = CustomerContent;
        }
        field(47; "Cheque No."; Code[20])
        {
            Caption = 'Cheque No.';
            DataClassification = CustomerContent;
        }
        field(48; "Cheque Date"; Date)
        {
            Caption = 'Cheque Date';
            DataClassification = CustomerContent;
        }
        field(49; "Account Type"; Enum "Gen. Journal Account Type")
        {
            Caption = 'Account Type';
            DataClassification = CustomerContent;
        }
        field(50; "Pay Amount"; Decimal)
        {
            Caption = 'Pay Amount';
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                if "Pay Amount" > "Net Salary" then
                    ERROR(Text002Lbl);
                if "Pay Amount" < 0 then
                    ERROR(Text003Lbl);
            end;
        }
        field(51; "Account No."; Code[20])
        {
            Caption = 'Account No.';
            TableRelation = IF ("Account Type" = CONST("G/L Account")) "G/L Account"."No."
            ELSE
            IF ("Account Type" = CONST("Bank Account")) "Bank Account"."No.";
            DataClassification = CustomerContent;
        }
        field(52; "Pay Method"; Option)
        {
            Caption = 'Pay Method';
            OptionCaption = 'Cash,Cheque,Bank Transfer';
            OptionMembers = Cash,Cheque,"Bank Transfer";
            DataClassification = CustomerContent;
        }
        field(53; Blocked; Boolean)
        {
            Caption = 'Blocked';
            DataClassification = CustomerContent;
        }
        field(54; "Monthly Exp"; Decimal)
        {
            Caption = 'Monthly Exp';
            DataClassification = CustomerContent;
        }
        field(56; Trainee; Boolean)
        {
            Caption = 'Trainee';
            DataClassification = CustomerContent;
        }
        field(57; "Net Payable"; Decimal)
        {
            Caption = 'Net Payable';
            DataClassification = CustomerContent;
        }
        field(60; "New Employment Days"; Integer)
        {
            CalcFormula = Count("Daily Attendance B2B" WHERE("Employee No." = FIELD("Employee Code"),
                                                          Year = FIELD(Year),
                                                          Month = FIELD("Pay Slip Month"),
                                                          "Attendance Type" = FILTER(= " ")));
            Caption = 'New Employment Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(61; "Location Code"; Code[20])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = "Payroll Locations B2B"."Location Code";
            DataClassification = CustomerContent;
        }
        field(70; "Leave Pay Cadre"; Code[50])
        {
            Caption = 'Leave Pay Cadre';
            NotBlank = true;
            TableRelation = Lookup_B2B."Lookup Name" WHERE("Lookup Type" = CONST(22));
            DataClassification = CustomerContent;
        }
        field(81; "Department Code"; Code[20])
        {
            Caption = 'Department Code';
            TableRelation = Lookup_B2B."Lookup Name" WHERE("LookupType Name" = CONST('DEPARTMENTS'));
            DataClassification = CustomerContent;
        }
        field(83; "Physical Location"; Code[20])
        {
            Caption = 'Physical Location';
            DataClassification = CustomerContent;
        }
        field(85; "Bank Account No."; Code[20])
        {
            Caption = 'Bank Account No.';
            DataClassification = CustomerContent;
        }
        field(101; "Emp Posting Group"; Code[20])
        {
            Caption = 'Emp Posting Group';
            TableRelation = "Employee Posting Group B2B".Code;
            DataClassification = CustomerContent;
        }
        field(102; "Payroll Bus. Posting Group"; Code[20])
        {
            Caption = 'Payroll Bus. Posting Group';
            TableRelation = "Payroll Bus. Post Group B2B".Code;
            DataClassification = CustomerContent;
        }
        field(105; "LOP Adj Days"; Decimal)
        {
            CalcFormula = Sum("Attendance Lines B2B"."LOP Adj." WHERE("Document Type" = CONST("Lop Adj"),
                                                                   "Employee Code" = FIELD("Employee Code"),
                                                                   Month = FIELD("Pay Slip Month"),
                                                                   Year = FIELD(Year),
                                                                   Status = CONST(Approved)));
            Caption = 'LOP Adj Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(110; "Computed Gross Salary"; Decimal)
        {
            Caption = 'Computed Gross Salary';
            DataClassification = CustomerContent;
        }
        field(150; "Reprocess Check"; Boolean)
        {
            Caption = 'Reprocess Check';
            DataClassification = CustomerContent;
        }
        field(151; "Rounding Amount"; Decimal)
        {
            Caption = 'Rounding Amount';
            DataClassification = CustomerContent;
        }
        field(153; "C Off Hours"; Decimal)
        {
            CalcFormula = Sum("Daily Attendance B2B"."C Off Hours" WHERE("Employee No." = FIELD("Employee Code"),
                                                                      Year = FIELD(Year),
                                                                      Month = FIELD("Pay Slip Month"),
                                                                      "C Off Hours" = FILTER(>= 4)));
            Caption = 'C Off Hours';
            FieldClass = FlowField;
        }
        field(160; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Open,Released';
            OptionMembers = Open,Released;
            DataClassification = CustomerContent;
        }
        field(163; "Dimesion Code"; Code[20])
        {
            Caption = 'Dimesion Code';
            TableRelation = "Dimension Value".Code WHERE("Global Dimension No." = CONST(1));
            DataClassification = CustomerContent;
        }
        field(170; "Arrear Net Amount"; Decimal)
        {
            Caption = 'Arrear Net Amount';
            DataClassification = CustomerContent;
        }
        field(171; "Arrears Included"; Boolean)
        {
            Caption = 'Arrears Included';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(172; "Arrear Additions"; Decimal)
        {
            CalcFormula = Sum("Processed Salary B2B"."Arrear Amount" WHERE("Employee Code" = FIELD("Employee Code"),
                                                                        "Add/Deduct" = CONST(Addition),
                                                                        "Arrear Amount" = FILTER(<> 0),
                                                                        "Arrears Not Posted" = CONST(true)));
            Caption = 'Arrear Additions';
            FieldClass = FlowField;
        }
        field(173; "Arrear Deductions"; Decimal)
        {
            CalcFormula = Sum("Processed Salary B2B"."Arrear Amount" WHERE("Employee Code" = FIELD("Employee Code"),
                                                                        "Add/Deduct" = CONST(Deduction),
                                                                        "Add/Deduct Code" = FILTER('<> EMP. ESI&<>EMP. PF'),
                                                                        "Arrear Amount" = FILTER(<> 0),
                                                                        "Arrears Not Posted" = CONST(true)));
            Caption = 'Arrear Deductions';
            FieldClass = FlowField;
        }
        field(174; "Arrear Amt Paid"; Decimal)
        {
            Caption = 'Arrear Amt Paid';
            DataClassification = CustomerContent;
        }
        field(175; "Arrear Amt Payable"; Decimal)
        {
            Caption = 'Arrear Amt Payable';
            DataClassification = CustomerContent;
        }
        field(176; "Arrear Amt Pay"; Decimal)
        {
            Caption = 'Arrear Amt Pay';
            DataClassification = CustomerContent;
        }
        field(177; "Remaining Arrear Amt"; Decimal)
        {
            Caption = 'Remaining Arrear Amt';
            DataClassification = CustomerContent;
        }
        field(182; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
            DataClassification = CustomerContent;

            trigger OnLookup();
            begin
                ShowDocDim();
            end;
        }
        field(183; "Outdoor Days"; Integer)
        {
            CalcFormula = Count("Daily Attendance B2B" WHERE("Employee No." = FIELD("Employee Code"),
                                                          Month = FIELD("Pay Slip Month"),
                                                          Year = FIELD(Year),
                                                          "Outdoor Duty" = CONST(true)));
            Caption = 'Outdoor Days';
            Editable = false;
            FieldClass = FlowField;
        }
        field(184; "Pay Salary"; Boolean)
        {

            DataClassification = CustomerContent;
        }
        field(500; "Early Going Hours"; Decimal)
        {
            CalcFormula = Sum("Daily Attendance B2B"."Early Going Hrs" WHERE("Employee No." = FIELD("Employee Code"),
                                                                   Year = FIELD(Year),
                                                                   Month = FIELD("Pay Slip Month"),
                                                                   "Early Going Hrs" = FILTER(<> 0)));
            Caption = 'Early Going Hours';
            FieldClass = FlowField;
            Editable = false;
        }
        field(505; "No G/L Posting"; Boolean)
        {
            Caption = 'Outsourced Employee';
            Editable = false;
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(Key1; "Employee Code", "Pay Slip Month", Year, "Line No.")
        {
            SumIndexFields = "Net Salary";
        }
        key(Key2; "Employee Code", Posted)
        {
            SumIndexFields = "Remaining Amount";
        }
        key(Key3; "Employee Code", "Pay Slip Month", Year)
        {
            Enabled = false;
        }
        key(Key5; "Pay Slip Month", Year, PayCadre, Blocked)
        {
        }
    }

    fieldgroups
    {
    }

    var

        DimMgt: Codeunit 408;
        Text001Lbl: Label 'This Record is Already Processed';
        Text002Lbl: Label 'Pay Amount cannot exceed Net Salary';
        Text003Lbl: Label 'You cannot enter Negative Amounts';

    procedure CreateDim(Type1: Integer; No1: Code[20]; var MonthlyAttendance: Record "Monthly Attendance B2B");
    var
        SourceCodeSetup: Record "Source Code Setup";
        TableID: array[10] of Integer;
        No: array[10] of Code[20];
        OldDimSetID: Integer;
    begin
        with MonthlyAttendance do begin
            SourceCodeSetup.GET();
            TableID[1] := Type1;
            No[1] := No1;
            MonthlyAttendance."Shortcut Dimension 1 Code" := '';
            MonthlyAttendance."Shortcut Dimension 2 Code" := '';
            OldDimSetID := "Dimension Set ID";
            "Dimension Set ID" :=
              DimMgt.GetDefaultDimID(TableID, No, '', "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code", "Dimension Set ID", DATABASE::"Employee B2B");
            DimMgt.UpdateGlobalDimFromDimSetID("Dimension Set ID", "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
        end;
    end;

    local procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20]);
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        DimMgt.ValidateShortcutDimValues(FieldNumber, ShortcutDimCode, "Dimension Set ID");
        if "Employee Code" <> '' then
            MODIFY();
    end;

    procedure ShowDocDim();
    var
        OldDimSetID: Integer;
    begin
        OldDimSetID := "Dimension Set ID";
        "Dimension Set ID" :=
          DimMgt.EditDimensionSet(
            "Dimension Set ID", STRSUBSTNO('%1 %2 %3 %4', "Employee Code", "Pay Slip Month", Year, "Line No."),
            "Shortcut Dimension 1 Code", "Shortcut Dimension 2 Code");
    end;
}

