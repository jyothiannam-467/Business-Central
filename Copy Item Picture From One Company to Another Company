pageextension 50112 ItemPictureExt extends "Item Picture"
{
    actions
    {
        addafter(ExportFile)
        {
            action(CopyToOtherCompany)
            {
                ApplicationArea = All;
                Caption = 'Copy to other company';
                Image = Copy;

                trigger OnAction()
                var
                    CompanyRec: Record Company;
                    Item: Record Item;
                    ItemTenantMedia: Record "Tenant Media";
                    InStr: InStream;
                    FileName: Text;
                begin
                    FileName := '';
                    CompanyRec.Reset();
                    if Page.RunModal(Page::Companies, CompanyRec) = ACTION::LookupOK then begin
                        Item.Reset();
                        Item.ChangeCompany(CompanyRec.Name);
                        if Page.RunModal(Page::"Item List", Item) = ACTION::LookupOK then
                            if Rec.Picture.Count > 0 then begin
                                ItemTenantMedia.Get(Rec.Picture.Item(1));
                                ItemTenantMedia.CalcFields(Content);
                                ItemTenantMedia.Content.CreateInStream(InStr, TextEncoding::UTF8);
                                FileName := Item.Description + '.png';
                                Item.Picture.ImportStream(InStr, FileName);
                                Item.Modify(true);
                                Message('Item picture copied to company ' + CompanyRec.Name + ' Item No. ' + Item."No.");
                            end;
                    end;
                end;
            }
        }
    }
}
