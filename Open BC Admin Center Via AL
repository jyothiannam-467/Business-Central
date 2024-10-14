pageextension 50119 UsersExt extends Users
{
    actions
    {
        addafter("Update users from Office")
        {
            action("Open Admin Center")
            {
                ApplicationArea = All;
                Caption = 'Open Admin Center';
                Image = Open;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    M365License: Codeunit "Microsoft 365 License";
                begin
                    // Opens the Business Central admin center.
                    M365License.OpenBCAdminCenter();
                end;
            }
            action("Open M365 Admin Center")
            {
                ApplicationArea = All;
                Caption = 'Open M365 Admin Center';
                Image = Open;
                Promoted = true;
                PromotedCategory = Process;
                trigger OnAction()
                var
                    M365License: Codeunit "Microsoft 365 License";
                begin
                    // Opens the M365 admin center.
                    M365License.OpenM365AdminCenter();
                end;
            }
        }
    }
}
