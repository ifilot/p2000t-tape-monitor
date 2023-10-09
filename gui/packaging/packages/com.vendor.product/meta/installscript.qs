function Component()
{
    // default constructor
}

Component.prototype.createOperations = function()
{
    component.createOperations();

    if (systemInfo.productType === "windows") {
        component.addOperation("CreateShortcut", "@TargetDir@/p2000t-fat-flasher", 
                               "@StartMenuDir@/P2000T FAT Flasher.lnk",
                               "workingDirectory=@TargetDir@", 
                               "iconPath=@TargetDir@/icon.ico",
                               "description=Open P2000T FAT Flasher");
    }
}