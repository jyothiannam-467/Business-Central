table 33001217 "Daily Attendance B2B"
{
    // version B2BHR1.00.00

    Caption = 'Daily Attendance';
    DrillDownPageID = "Daily Attendance List B2B";
    LookupPageID = "Daily Attendance List B2B";
    DataClassification = CustomerContent;
    fields
    {
        field(1; "Employee No."; Code[20])
        {
            Caption = 'Employee No.';
            TableRelation = "Employee B2B";
            DataClassification = CustomerContent;
        }
        field(2; Date; Date)
        {
            Caption = 'Date';
            DataClassification = CustomerContent;
        }
        field(3; "Time In"; Time)
        {
            Caption = 'Time In';
            DataClassification = CustomerContent;

            trigger OnValidate();
            var

            begin
                CheckTime := 130000T;
                if "Time Out" <> 0T then
                    if ("Time In" > CheckTime) and ("Time Out" < CheckTime) then begin
                        StartDateTime := CREATEDATETIME(Date, "Time In");
                        EndDateTime := CREATEDATETIME((Date + 1), "Time Out");
                        validate("Hours Worked", (ABS(((StartDateTime - EndDateTime) / 3600000)) - "Break Duration"));
                    end else
                        validate("Hours Worked", (ABS((("Time In" - "Time Out") / 3600000)) - "Break Duration"));



                if "Hours Worked" > "Actual Hrs" then begin
                    "OT Hrs" := "Hours Worked" - "Actual Hrs";
                    "Late Hrs" := 0;
                end else
                    if "Hours Worked" < "Actual Hrs" then begin
                        "Late Hrs" := "Actual Hrs" - "Hours Worked";
                        "OT Hrs" := 0;
                    end else begin
                        "Late Hrs" := 0;
                        "OT Hrs" := 0;
                    end;
                IF "Actual Time In" <> 0T THEN
                    "Late Hrs" := ABS("Time In" - "Actual Time In") / 3600000;

                if (WeeklyOff <> 0) or (Holiday <> 0) then
                    "OT Hrs" := "Hours Worked";

            end;
        }
        field(4; "Time Out"; Time)
        {
            Caption = 'Time Out';
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                CheckTime := 130000T;
                if "Time Out" <> 0T then
                    if ("Time In" > CheckTime) and ("Time Out" < CheckTime) then begin
                        StartDateTime := CREATEDATETIME(Date, "Time In");
                        EndDateTime := CREATEDATETIME((Date + 1), "Time Out");
                        validate("Hours Worked", (ABS(((StartDateTime - EndDateTime) / 3600000)) - "Break Duration"));
                    end else
                        validate("Hours Worked", (ABS((("Time In" - "Time Out") / 3600000)) - "Break Duration"));

                if "Hours Worked" > "Actual Hrs" then begin
                    "OT Hrs" := "Hours Worked" - "Actual Hrs";
                    "Late Hrs" := 0;
                end else
                    if "Hours Worked" < "Actual Hrs" then begin
                        //if "Time Out" < "Actual Time Out" then
                        //   "Early Going Hrs" := "Actual Hrs" - "Hours Worked"
                        // else
                        //"Late Hrs" := "Actual Hrs" - "Hours Worked";
                        "OT Hrs" := 0;
                    end else begin
                        "Late Hrs" := 0;
                        "OT Hrs" := 0;
                    end;

                if (WeeklyOff <> 0) or (Holiday <> 0) then
                    "OT Hrs" := "Hours Worked";
                //B2BDNROn12Sep2023>>
                if "Time Out" < "Actual Time Out" then
                    "Early Going Hrs" := ABS("Actual Time Out" - "Time Out") / 3600000;
                //B2BDNROn12Sep2023<<
            end;
        }
        field(5; "Hours Worked"; Decimal)
        {
            Caption = 'Hours Worked';
            DataClassification = CustomerContent;
            //B2BDNROn24Jun2023>>
            trigger OnValidate()
            begin
                IF "Non-Working" OR (Leave >= 1) THEN
                    EXIT;
                IF ("Hours Worked" >= "Actual Hrs") OR ("Hours Worked" > "Actual Hrs" / 2) THEN BEGIN
                    Present := 1;
                    Absent := 0;
                END ELSE
                    IF ("Hours Worked" = "Actual Hrs" / 2) THEN BEGIN
                        Present := 0.5;
                        Absent := 0.5;
                    END ELSE BEGIN
                        Present := 0;
                        Absent := 1;
                    END;
                IF Present > 0 THEN
                    "Attendance Type" := "Attendance Type"::Present
                ELSE
                    "Attendance Type" := "Attendance Type"::Absent;
            end;
            //B2BDNROn24Jun2023<<
        }
        field(6; "Shift Code"; Code[20])
        {
            Caption = 'Shift Code';
            TableRelation = "Shift Master B2B";
            DataClassification = CustomerContent;
        }
        field(7; "Non-Working"; Boolean)
        {
            Caption = 'Non-Working';
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                if "Non-Working" = true then
                    "Attendance Type" := 0
            end;
        }
        field(8; "Non-Working Type"; Option)
        {
            Caption = 'Non-Working Type';
            OptionCaption = ' ,Holiday,OffDay';
            OptionMembers = " ",Holiday,OffDay;
            DataClassification = CustomerContent;
        }
        field(9; "Attendance Type"; Option)
        {
            Caption = 'Attendance Type';
            OptionCaption = ' ,Present,Absent,Leave';
            OptionMembers = " ",Present,Absent,Leave;
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                if "Non-Working" = true then
                    if "Attendance Type" <> 0 then
                        ERROR(Text000Lbl);


                if "Attendance Type" = "Attendance Type"::" " then
                    ERROR(Text004Lbl);

                case "Attendance Type" of
                    "Attendance Type"::Present:
                        case "Halfday Status" of
                            "Halfday Status"::"HD Present":
                                ERROR(Text005Lbl);
                            "Halfday Status"::"HD Absent":
                                begin
                                    Present := 0.5;
                                    Absent := 0.5;
                                    Leave := 0;
                                end;
                            "Halfday Status"::"HD Leave":
                                begin
                                    Present := 0.5;
                                    Absent := 0;
                                    Leave := 0.5;
                                end;
                            "Halfday Status"::" ":
                                begin
                                    Present := 1;
                                    Absent := 0;
                                    Leave := 0;
                                end;
                        end;
                    "Attendance Type"::Absent:
                        case "Halfday Status" of
                            "Halfday Status"::"HD Present":
                                begin
                                    Present := 0.5;
                                    Absent := 0.5;
                                    Leave := 0;
                                end;
                            "Halfday Status"::"HD Absent":
                                ERROR(Text005Lbl);
                            "Halfday Status"::"HD Leave":
                                begin
                                    Present := 0;
                                    Absent := 0.5;
                                    Leave := 0.5;
                                end;
                            "Halfday Status"::" ":
                                begin
                                    Present := 0;
                                    Absent := 1;
                                    Leave := 0;
                                end;
                        end;
                    "Attendance Type"::Leave:
                        ERROR(Text003Lbl);
                end;
            end;
        }
        field(10; "Day No."; Integer)
        {
            Caption = 'Day No.';
            DataClassification = CustomerContent;
        }
        field(11; WeeklyOff; Decimal)
        {
            Caption = 'WeeklyOff';
            DataClassification = CustomerContent;
        }
        field(12; Holiday; Decimal)
        {
            Caption = 'Holiday';
            DataClassification = CustomerContent;
        }
        field(13; Year; Integer)
        {
            Caption = 'Year';
            DataClassification = CustomerContent;
        }
        field(14; Month; Integer)
        {
            Caption = 'Month';
            ValuesAllowed = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12;
            DataClassification = CustomerContent;
        }
        field(15; "Employee Name"; Text[50])
        {
            Caption = 'Employee Name';
            DataClassification = CustomerContent;
        }
        field(16; "Leave Code"; Code[20])
        {
            Caption = 'Leave Code';
            DataClassification = CustomerContent;
        }
        field(17; Present; Decimal)
        {
            Caption = 'Present';
            DataClassification = CustomerContent;
        }
        field(18; Absent; Decimal)
        {
            Caption = 'Absent';
            DataClassification = CustomerContent;
        }
        field(19; Leave; Decimal)
        {
            Caption = 'Leave';
            DataClassification = CustomerContent;
        }
        field(20; "Actual Time In"; Time)
        {
            Caption = 'Actual Time In';
            DataClassification = CustomerContent;
        }
        field(21; "Actual Time Out"; Time)
        {
            Caption = 'Actual Time Out';
            DataClassification = CustomerContent;
        }
        field(22; "OT Hrs"; Decimal)
        {
            Caption = 'OT Hrs';
            DataClassification = CustomerContent;
        }
        field(23; "OT Approved Hrs"; Decimal)
        {
            Caption = 'OT Approved Hrs';
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                if "OT Approved Hrs" > "OT Hrs" then
                    ERROR(Text002Lbl);

                if "OT Approved Hrs" > 0 then
                    "OT Approved" := true;
            end;
        }
        field(24; "Actual Hrs"; Decimal)
        {
            Caption = 'Actual Hrs';
            DataClassification = CustomerContent;
        }
        field(25; "Break Duration"; Decimal)
        {
            Caption = 'Break Duration';
            DataClassification = CustomerContent;
        }
        field(26; PayCadre; Code[30])
        {
            Caption = 'PayCadre';
            DataClassification = CustomerContent;
        }
        field(27; "Hrs Worked"; Decimal)
        {
            CalcFormula = Sum("Employee Timings B2B"."No.of Hours" WHERE("Employee No." = FIELD("Employee No."),
                                                                      Date = FIELD(Date)));
            Caption = 'Hrs Worked';
            FieldClass = FlowField;
        }
        field(28; "Not Joined"; Decimal)
        {
            Caption = 'Not Joined';
            DataClassification = CustomerContent;
        }
        field(29; Activity; Integer)
        {
            CalcFormula = Count("Employee Performance Line B2B" WHERE("Employee No." = FIELD("Employee No.")));
            Caption = 'Activity';
            FieldClass = FlowField;
        }
        field(35; "Time Punches"; Integer)
        {
            CalcFormula = Count("Daily Time Punches B2B" WHERE("Employee No." = FIELD("Employee No."),
                                                            Date = FIELD(Date)));
            Caption = 'Time Punches';
            Editable = false;
            FieldClass = FlowField;
        }
        field(50; "Attendance Month"; Integer)
        {
            Caption = 'Attendance Month';
            DataClassification = CustomerContent;
        }
        field(51; Authorised; Boolean)
        {
            Caption = 'Authorised';
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                if "Late Time" > 0 then
                    if Authorised then
                        "Attendance Type" := "Attendance Type"::Present
                    else
                        "Attendance Type" := "Attendance Type"::Absent;
            end;
        }
        field(52; "Late Time"; Duration)
        {
            Caption = 'Late Time';
            DataClassification = CustomerContent;
        }
        field(60; "Compensatory Leave"; Boolean)
        {
            Caption = 'Compensatory Leave';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(61; "Leave Application No."; Code[20])
        {
            Caption = 'Leave Application No.';
            DataClassification = CustomerContent;
        }
        field(62; "Halfday Status"; Option)
        {
            Caption = 'Halfday Status';
            OptionCaption = ' ,HD Present,HD Absent,HD Leave';
            OptionMembers = " ","HD Present","HD Absent","HD Leave";
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                case "Halfday Status" of
                    "Halfday Status"::"HD Present":
                        if "Attendance Type" = "Attendance Type"::Present then
                            ERROR(Text006Lbl)
                        else
                            if "Attendance Type" = "Attendance Type"::Absent then begin
                                Present := 0.5;
                                Absent := 0.5;
                                Leave := 0;
                            end;
                    "Halfday Status"::"HD Absent":
                        if "Attendance Type" = "Attendance Type"::Present then begin
                            Present := 0.5;
                            Absent := 0.5;
                            Leave := 0;
                        end else
                            if "Attendance Type" = "Attendance Type"::Absent then
                                ERROR(Text006Lbl);

                    "Halfday Status"::"HD Leave":
                        ERROR(Text003Lbl);

                end;
            end;
        }
        field(63; "Session Time"; Option)
        {
            Caption = 'Session Time';
            OptionCaption = ' ,First Half,Second Half';
            OptionMembers = " ","First Half","Second Half";
            DataClassification = CustomerContent;
        }
        field(65; "Late Hrs"; Decimal)
        {
            Caption = 'Late Hrs';
            DataClassification = CustomerContent;
        }
        field(70; "Early Going Hrs"; Decimal)
        {
            Caption = 'Early Going Hrs';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(72; "Current Shift"; Code[20])
        {
            Caption = 'Current Shift';
            Editable = false;
            TableRelation = "Shift Master B2B";
            DataClassification = CustomerContent;
        }
        field(74; "Revised Shift"; Code[20])
        {
            Caption = 'Revised Shift';
            Editable = false;
            TableRelation = "Shift Master B2B";
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                if ShiftMaster.GET("Revised Shift", "Location Code") then begin
                    "Break Duration" := ShiftMaster."Break Duration";
                    "Actual Hrs" := ABS(("Actual Time Out" - "Actual Time In") / 3600000) - "Break Duration";
                end;
            end;
        }
        field(81; "Comp Off"; Boolean)
        {
            Caption = 'Comp Off';
            DataClassification = CustomerContent;
        }
        field(82; "C Off Hours"; Decimal)
        {
            Caption = 'C Off Hours';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(100; Remarks; Text[100])
        {
            Caption = 'Remarks';
            DataClassification = CustomerContent;
        }
        field(101; "Location Code"; Code[20])
        {
            Caption = 'Location Code';
            Editable = false;
            TableRelation = "Payroll Locations B2B"."Location Code";
            DataClassification = CustomerContent;
        }
        field(102; "Revised Shift Code"; Code[20])
        {
            Caption = 'Revised Shift Code';
            NotBlank = true;
            TableRelation = "Shift Master B2B";
            DataClassification = CustomerContent;
        }
        field(103; "OT Approved"; Boolean)
        {
            Caption = 'OT Approved';
            DataClassification = CustomerContent;
        }
        field(110; "Leave Pay Cadre"; Code[50])
        {
            Caption = 'Leave Pay Cadre';
            NotBlank = true;
            TableRelation = Lookup_B2B."Lookup Name" WHERE("Lookup Type" = CONST(22));
            DataClassification = CustomerContent;
        }
        field(120; "Worked Hours"; Text[50])
        {
            Caption = 'Worked Hours';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(123; "Late Coming Minutes"; Text[50])
        {
            Caption = 'Late Coming Minutes';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(125; "Early Going Minutes"; Text[50])
        {
            Caption = 'Early Going Minutes';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(128; "OT Minutes"; Text[50])
        {
            Caption = 'OT Minutes';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(130; "OT Approved Minutes"; Text[50])
        {
            Caption = 'OT Approved Minutes';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(140; "Manual Attendance"; Boolean)
        {
            Caption = 'Manual Attendance';
            Editable = false;
            DataClassification = CustomerContent;
        }
        field(181; "Employee Movement"; Option)
        {
            Caption = 'Employee Movement';
            OptionCaption = ' ,On Duty,Tour';
            OptionMembers = " ","On Duty",Tour;
            DataClassification = CustomerContent;
        }
        field(182; "Outdoor Duty"; Boolean)
        {
            Caption = 'Outdoor Duty';
            DataClassification = CustomerContent;
        }
        field(183; "Lop Adj. Approved"; Boolean)
        {
            Caption = 'Lop Adj. Approved';
            DataClassification = CustomerContent;
        }
        field(184; "Lop Adj. Posted"; Boolean)
        {
            Caption = 'Lop Adj. Posted';
            DataClassification = CustomerContent;
        }
        field(185; "Approved User ID"; Code[50])
        {
            Caption = 'Approved User ID';
            TableRelation = User;
            DataClassification = CustomerContent;
        }
        field(186; "Approved Date & Time"; DateTime)
        {
            Caption = 'Approved Date & Time';
            DataClassification = CustomerContent;
        }
        field(187; "Lop Adj. Deduction Approved"; Boolean)
        {
            Caption = 'Lop Adj. Deduction Approved';
            DataClassification = CustomerContent;
        }
        field(188; "LOP Ded. Approved User ID"; Code[50])
        {
            Caption = 'LOP Ded. Approved User ID';
            DataClassification = CustomerContent;
        }
        field(189; "LOP Ded. Approved Date & Time"; DateTime)
        {
            Caption = 'LOP Ded. Approved Date & Time';
            DataClassification = CustomerContent;
        }
        field(190; "Day Count"; Decimal)
        {
            Caption = 'Day Count';
            DataClassification = CustomerContent;
        }
        field(191; "LOP Type"; Option)
        {
            Caption = 'LOP Type';
            OptionCaption = ' ,Half Day,Full Day';
            OptionMembers = " ","Half Day","Full Day";
            DataClassification = CustomerContent;

            trigger OnValidate();
            begin
                if "LOP Type" = "LOP Type"::"Half Day" then
                    "Day Count" := 0.5
                else
                    "Day Count" := 1;
            end;
        }
        field(192; "Comp Off Hrs."; Decimal)
        {
            DataClassification = CustomerContent;
            trigger OnValidate()
            begin
                CalculateCompOff();
            end;
        }
        field(193; "Comp Off Added"; Boolean)
        {
            DataClassification = CustomerContent;

        }
    }

    keys
    {
        key(Key1; "Employee No.", Date)
        {
            SumIndexFields = WeeklyOff, Holiday;
        }
        key(Key2; Year, Month, WeeklyOff, Holiday, Present, Absent, Leave, "Leave Code", "C Off Hours")
        {
            SumIndexFields = WeeklyOff, Holiday, Present, Absent, Leave, "C Off Hours";
        }
        key(Key3; "Employee No.", Year, Month, "OT Approved Hrs")
        {
            SumIndexFields = "OT Approved Hrs";
        }
        key(Key4; "Employee No.", Year, Month, "Late Hrs")
        {
            SumIndexFields = "Late Hrs";
        }
    }

    fieldgroups
    {
    }

    var
        ShiftMaster: Record "Shift Master B2B";
        Text000Lbl: Label 'Invalid Attendance type';
        StartDateTime: DateTime;
        EndDateTime: DateTime;
        Text002Lbl: Label 'OT Approved Hrs should be less than or equal to the OT Hrs';
        CheckTime: Time;
        Text003Lbl: Label 'You should not change the leave type manual. Leave application is necessary.';
        Text004Lbl: Label 'Attendance type should not be blank.';
        Text005Lbl: Label 'Cancell the Leaves if you want to change the status.';
        Text006Lbl: Label 'need not select';


    procedure CalculateCompOff()
    var
        LeaveMaster: Record "Leave Master B2B";
        DetailedLeaveRecord: Record "Detailed Leave Records B2B";
        InitDetailedLeaveRecord: Record "Detailed Leave Records B2B";
        HrSetup: Record "HR Setup B2B";
        EmployeeB2B: Record "Employee B2B";
        EmployeeLeaves: Record "Employee Leaves B2B";
        ProvLeaves: Record "Provisional Leaves B2B";
        TempProvLeaves: Record "Provisional Leaves B2B";
        PayrollYear: Record "Payroll Year B2B";
        GradeWiseLeaves: Record "Grade Wise Leaves B2B";
        RemainCompOffBal: Decimal;
        CompLeaveBal: Decimal;
        CompOffBalance: Decimal;
    begin
        Clear(CompLeaveBal);
        Clear(CompOffBalance);
        HrSetup.Get();
        PayrollYear.RESET();
        PayrollYear.SETRANGE("Year Type", 'LEAVE YEAR');
        PayrollYear.SETRANGE(Closed, false);
        if PayrollYear.FINDFIRST() then;
        if "Comp Off Hrs." <> 0 then begin
            CompOffBalance := "Comp Off Hrs.";
            if CompOffBalance <> 0 then begin
                RemainCompOffBal := CompOffBalance mod "Actual Hrs";
                CompLeaveBal := CompOffBalance div "Actual Hrs";
                if RemainCompOffBal <> 0 then
                    if RemainCompOffBal >= "Actual Hrs" / 2 then
                        CompLeaveBal += 0.5;


            end;
        end;
        EmployeeB2B.Get("Employee No.");
        if (CompLeaveBal <> 0) then begin
            EmployeeLeaves.Reset();
            EmployeeLeaves.SetRange("No.", "Employee No.");
            EmployeeLeaves.SetRange("Leave Code", HrSetup."Compensatory Leave Code");
            if EmployeeLeaves.FindLast() then;
            DetailedLeaveRecord.Reset();
            if DetailedLeaveRecord.FindLast() then;
            InitDetailedLeaveRecord.Init();
            InitDetailedLeaveRecord."Entry No." := DetailedLeaveRecord."Entry No." + 1;
            InitDetailedLeaveRecord."Employee No." := "Employee No.";
            InitDetailedLeaveRecord."Entry Date" := Date;
            InitDetailedLeaveRecord.VALIDATE("Leave Code", HrSetup."Compensatory Leave Code");
            LeaveMaster.Get(HrSetup."Compensatory Leave Code", "Location Code");
            InitDetailedLeaveRecord."Leave Description" := LeaveMaster.Description;
            EmployeeB2B.Get(InitDetailedLeaveRecord."Employee No.");
            InitDetailedLeaveRecord."Leave Pay Cadre" := EmployeeLeaves."Leave Pay Cadre";
            InitDetailedLeaveRecord."Entry Type" := InitDetailedLeaveRecord."Entry Type"::Entitlement;
            InitDetailedLeaveRecord."Posting Date" := WORKDATE();
            InitDetailedLeaveRecord."No. of Leaves" := CompLeaveBal;
            InitDetailedLeaveRecord.Month := DATE2DMY(InitDetailedLeaveRecord."Entry Date", 2);
            InitDetailedLeaveRecord.Year := DATE2DMY(InitDetailedLeaveRecord."Entry Date", 3);
            InitDetailedLeaveRecord.Insert(true);
            ProvLeaves.INIT();
            ProvLeaves."Employee No." := "Employee No.";
            ProvLeaves."Employee Name" := EmployeeB2B."First Name";
            ProvLeaves."Leave Code" := HrSetup."Compensatory Leave Code";
            ProvLeaves."Leave Descriptioon" := LeaveMaster.Description;
            ProvLeaves."No.of Leaves" := CompLeaveBal;
            ProvLeaves."Remaining Leaves" := CompLeaveBal;
            ProvLeaves.Status := ProvLeaves.Status::Open;
            ProvLeaves.Month := Date2DMY(Date, 2);
            ProvLeaves.Year := Date2DMY(Date, 3);
            ProvLeaves."Leave Year Start Date" := PayrollYear."Year Start Date";
            ProvLeaves."Leave Year End Date" := PayrollYear."Year End Date";
            ProvLeaves."Prev. Month  Balance" := CompLeaveBal;
            ProvLeaves."Period Start Date" := PayrollYear."Year Start Date";
            GradeWiseLeaves.RESET();
            GradeWiseLeaves.SETRANGE("Leave Code", HrSetup."Compensatory Leave Code");
            GradeWiseLeaves.SETRANGE("Leave Pay Cadre", EmployeeB2B."Leave Pay Cadre");
            GradeWiseLeaves.SETRANGE("Location Code", EmployeeB2B."Location Code");
            GradeWiseLeaves.FINDFIRST();
            ProvLeaves."Period End Date" := CALCDATE('<-1D>', CALCDATE(GradeWiseLeaves."Crediting Interval", ProvLeaves."Period Start Date"));

            TempProvLeaves.RESET();
            TempProvLeaves.SETRANGE("Employee No.", ProvLeaves."Employee No.");
            TempProvLeaves.SETRANGE("Leave Code", ProvLeaves."Leave Code");
            TempProvLeaves.SetRange(Status, TempProvLeaves.Status::Open);
            if not TempProvLeaves.FINDFIRST() then
                ProvLeaves.INSERT()
            else begin
                TempProvLeaves."Prev. Month  Balance" += CompLeaveBal;
                TempProvLeaves."No.of Leaves" += CompLeaveBal;
                TempProvLeaves."Remaining Leaves" += CompLeaveBal;
                TempProvLeaves.Status := TempProvLeaves.Status::Open;
                TempProvLeaves.MODIFY();
            end;
            "Comp Off Added" := true;
            Modify(true);
        end;
        //CompOffLapse();
    end;

    procedure CompOffLapse()
    var
        LeaveMaster: Record "Leave Master B2B";
        DetailedLeaveRecord: Record "Detailed Leave Records B2B";
        HrSetup: Record "HR Setup B2B";
        EmpoyeeB2B: Record "Employee B2B";
        LastDetailedLeaveRecord: Record "Detailed Leave Records B2B";
        InitDetailedLeaveRecord: Record "Detailed Leave Records B2B";
        EmployeeLeaves: Record "Employee Leaves B2B";
        LapsePeriod: Text;
    begin
        HrSetup.Get();
        LeaveMaster.Reset();
        LeaveMaster.SetRange("Leave Code", HrSetup."Compensatory Leave Code");
        if LeaveMaster.FINDFIRST() then begin
            LeaveMaster.TestField("Lapse Period");
            LapsePeriod := '-' + Format(LeaveMaster."Lapse Period");
        end;
        EmpoyeeB2B.Get("Employee No.");
        DetailedLeaveRecord.Reset();
        DetailedLeaveRecord.SetRange("Employee No.", "Employee No.");
        DetailedLeaveRecord.SetRange("Leave Code", LeaveMaster."Leave Code");
        DetailedLeaveRecord.SetFilter("Entry Date", '<=%1', CalcDate(LapsePeriod, Date));
        DetailedLeaveRecord.SetRange(Lapse, false);
        if DetailedLeaveRecord.FindSet() then begin

            EmployeeLeaves.Reset();
            EmployeeLeaves.SetRange("No.", "Employee No.");
            EmployeeLeaves.SetRange("Leave Code", HrSetup."Compensatory Leave Code");
            if EmployeeLeaves.FindLast() then;
            DetailedLeaveRecord.CalcSums("No. of Leaves");
            if DetailedLeaveRecord."No. of Leaves" > 0 then begin
                LastDetailedLeaveRecord.Reset();
                if LastDetailedLeaveRecord.FindLast() then;
                InitDetailedLeaveRecord.Init();
                InitDetailedLeaveRecord."Entry No." := LastDetailedLeaveRecord."Entry No." + 1;
                InitDetailedLeaveRecord."Employee No." := "Employee No.";
                InitDetailedLeaveRecord."Entry Date" := Date;
                InitDetailedLeaveRecord.VALIDATE("Leave Code", HrSetup."Compensatory Leave Code");
                LeaveMaster.Get(HrSetup."Compensatory Leave Code", "Location Code");
                InitDetailedLeaveRecord."Leave Description" := LeaveMaster.Description;
                EmpoyeeB2B.Get(InitDetailedLeaveRecord."Employee No.");
                InitDetailedLeaveRecord."Leave Pay Cadre" := EmployeeLeaves."Leave Pay Cadre";
                InitDetailedLeaveRecord."Entry Type" := InitDetailedLeaveRecord."Entry Type"::Lapse;
                InitDetailedLeaveRecord."Posting Date" := WORKDATE();

                InitDetailedLeaveRecord."No. of Leaves" += -DetailedLeaveRecord."No. of Leaves";
                InitDetailedLeaveRecord.Month := DATE2DMY(InitDetailedLeaveRecord."Entry Date", 2);
                InitDetailedLeaveRecord.Year := DATE2DMY(InitDetailedLeaveRecord."Entry Date", 3);
                InitDetailedLeaveRecord.Insert(true);
                DetailedLeaveRecord.ModifyAll(Lapse, true, true);

            end;
        end;
    end;
}

