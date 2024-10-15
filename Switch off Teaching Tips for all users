pageextension 50116 MyExtension extends "User Settings List"
{
    actions
    {
        addfirst(Processing)
        {
            action(DisableTeachingTips)
            {
                Caption = 'Disable Teaching Tips For All Users';
                Image = DisableBreakpoint;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ZYTeachingTips: Codeunit ZYTeachingTips;
                begin
                    ZYTeachingTips.DisableTeachingTips();
                end;
            }
            action(EnableTeachingTips)
            {
                Caption = 'Enable Teaching Tips For All Users';
                Image = EnableBreakpoint;
                ApplicationArea = All;
                Promoted = true;
                PromotedCategory = Process;

                trigger OnAction()
                var
                    ZYTeachingTips: Codeunit ZYTeachingTips;
                begin
                    ZYTeachingTips.EnableTeachingTips();
                end;
            }
        }
    }
}

codeunit 50115 ZYTeachingTips
{
    Permissions = tabledata "Application User Settings" = rim;

    procedure DisableTeachingTips()
    var
        UserPersonalization: Record "User Personalization";
        ApplicationUserSettings: Record "Application User Settings";
        i: Integer;
    begin
        i := 0;
        UserPersonalization.Reset();
        if UserPersonalization.FindSet() then
            repeat
                if not ApplicationUserSettings.Get(UserPersonalization."User SID") then begin
                    ApplicationUserSettings.Init();
                    ApplicationUserSettings."User Security ID" := UserPersonalization."User SID";
                    ApplicationUserSettings."Teaching Tips" := false;
                    ApplicationUserSettings.Insert();
                    i += 1;
                end else begin
                    ApplicationUserSettings."Teaching Tips" := false;
                    ApplicationUserSettings.Modify();
                    i += 1;
                end;
            until UserPersonalization.Next() = 0;
        if i > 0 then
            Message('Teaching Tips disabled for %1 users.', i);
    end;

    procedure EnableTeachingTips()
    var
        UserPersonalization: Record "User Personalization";
        ApplicationUserSettings: Record "Application User Settings";
        i: Integer;
    begin
        i := 0;
        UserPersonalization.Reset();
        if UserPersonalization.FindSet() then
            repeat
                if not ApplicationUserSettings.Get(UserPersonalization."User SID") then begin
                    ApplicationUserSettings.Init();
                    ApplicationUserSettings."User Security ID" := UserPersonalization."User SID";
                    ApplicationUserSettings."Teaching Tips" := true;
                    ApplicationUserSettings.Insert();
                    i += 1;
                end else begin
                    ApplicationUserSettings."Teaching Tips" := true;
                    ApplicationUserSettings.Modify();
                    i += 1;
                end;
            until UserPersonalization.Next() = 0;
        if i > 0 then
            Message('Teaching Tips enabled for %1 users.', i);
    end;
}
