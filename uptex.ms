try destroyDialog dc_ro_MainScript catch();
global dc_ro_MainScript;
global dc_va_Distance;
global dc_va_OrgObject;
global dc_va_CloneObject;
global dc_va_TempClone = #();
global dc_va_INI = (Getdir #scripts)+ "\\MisterMo\\MisterMo.ini";
global dc_va_Version = "1.00";
fn dc_fn_GetSetting inputString = getINISetting dc_va_INI "Setting" inputString;
fn dc_fn_SetSetting inputString inputValue = setINISetting dc_va_INI "Setting" inputString (inputValue as string);
fn dc_fn_HasSetting inputString = hasINISetting dc_va_INI "Setting" inputString;
fn dc_fn_ResetSetting x y = if not dc_fn_HasSetting x then dc_fn_SetSetting x y;
fn dc_fn_ResetAll =
    (
        dc_fn_ResetSetting "dc_ui_KeepLayer" "true";
        dc_fn_ResetSetting "dc_ui_AlignClone" "true";
        dc_fn_ResetSetting "dc_ui_CloneType" "2";
        dc_fn_ResetSetting "dc_ui_ControllerType" "1";
        dc_fn_ResetSetting "dc_ui_Items" "1";
        dc_fn_ResetSetting "dc_ui_StartOffset" "0";
        dc_fn_ResetSetting "dc_ui_EndOffset" "0";
        dc_fn_ResetSetting "dc_ui_ShowPreview" "true";
        dc_fn_ResetSetting "dc_ui_DisplayAsBox" "false";
        dc_fn_ResetSetting "dc_ui_ItemLimitValue" "100";
        dc_fn_ResetSetting "dc_ui_ItemLimitEnable" "true";
    )
dc_fn_ResetAll();
fn dc_fn_MoveToLayer inputObj layerName =
    (
        if LayerManager.getLayerFromName layerName == undefined then LayerManager.newLayerFromName layerName;
        layerName = LayerManager.getLayerFromName layerName;
        layerName.current = true;
        if inputObj.layer.name != layerName then try layerName.addNode obj catch();
    )
rollout dc_ro_MainScript ("均分克隆 " + dc_va_Version) width:170 height:470;
(
    group "克隆物体"
    (
        radiobuttons dc_ui_ObjectToClone "" labels:#("第一个物体","第二个物体", "选择物体") offsets:#([0,0],[0,6],[0,12]) align:#left offset:[0,2];
        pickbutton dc_ui_PickObject "选择" width:50 height:17 align:#right offset:[2,-21];
        label sep1 "" offset:[0,-15];
    )
    group "克隆设置"
    (
        label dc_ui_ObjectLabel "物体:" align:#left across:2 offset:[-2,1];
        label dc_ui_ControllerLabel "Controller:" align:#left offset:[3,1];
        dropdownList dc_ui_CloneType "" items:#("复制", "关联", "参考") offset:[-4,0] across:2;
        dropdownList dc_ui_ControllerType "" items:#("复制", "关联") offset:[2,0];
        checkbox dc_ui_AlignClone "对齐克隆" offset:[-4,1] across:2;
        checkbox dc_ui_KeepLayer "保留层" offset:[0,1];
        label sep2 "" offset:[0,-15];
    )
    group "均分设置"
    (
        spinner dc_ui_Items "个数: " fieldWidth:65 range:[1,1e+06,1] type:#integer align:#right offset:[3,2];
        spinner dc_ui_Spacing "间隔: " fieldWidth:65 range:[0.01,1e+06,1] type:#worldUnits align:#right offset:[3,0];
        spinner dc_ui_StartOffset "起点偏移量: " fieldWidth:65 range:[-1e+06,1e+06,0] type:#worldUnits align:#right offset:[3,0];
        spinner dc_ui_EndOffset "终点偏移量: " fieldWidth:65 range:[-1e+06,1e+06,0] type:#worldUnits align:#right offset:[3,0];
        label sep3 "" offset:[0,-15];
    )
    group "克隆预览"
    (
        checkbox dc_ui_ShowPreview "开启" offset:[-3,0] across:2;
        checkbox dc_ui_DisplayAsBox "Box显示" offset:[0,0];
        checkbox dc_ui_ItemLimitEnable "个数限制" offset:[-3,0] across:2;
        spinner dc_ui_ItemLimitValue "" fieldWidth:65 range:[1,1e+06,1000] type:#integer align:#right offset:[3,-1];
        button dc_ui_RefreshPreview "刷新" width:152 offset:[0,0];
    )
    group "均分克隆"
    (
        button dc_ui_StartClone "确定克隆" width:152 height:39 offset:[0,2];
    )
    fn dc_fn_ClearTemp = undo off
    (
        try delete dc_va_TempClone catch();
        dc_va_TempClone = #();
    )
    fn dc_fn_SafePreview = if dc_ui_ItemLimitEnable.checked then
    (
        if (dc_ui_Items.value >= dc_ui_ItemLimitValue.value and dc_ui_ShowPreview.state) then;
        (
        messageBox "显示克隆预览已自动关闭,以避免冻结3dsMax视口中.请考虑减少项目数量." title:"均分克隆" icon:#warning;
        dc_ui_ShowPreview.state = false;
        dc_fn_ClearTemp();
        )
    )
    fn dc_ui_Clone mode = if (dc_va_OrgObject.count == 2 and isValidNode dc_va_OrgObject[1] and isValidNode dc_va_OrgObject[2]) then undo off
    (
        dc_fn_ClearTemp();
        local fObj = dc_va_OrgObject[1];
        local sObj = dc_va_OrgObject[2];
        local startPoint, endPoint;
        if dc_ui_StartOffset.value!= 0 then startPoint = fObj.pos + ((sObj.pos - fObj.pos) / (dc_va_Distance / dc_ui_StartOffset.value)) else startPoint = fObj.pos
        if dc_ui_StartOffset.value!= 0 then endPoint = sObj.pos + ((fObj.pos - sObj.pos) / (dc_va_Distance / dc_ui_EndOffset.value)) else endPoint = sObj.pos;
        local cloneObj, clonePos, cloneVector;
        local fRot, sRot, rotX, rotY, rotZ;
        local layerName;
        fRot = QuatToEuler fObj.rotation;
        sRot = QuatToEuler sObj.rotation;
        case dc_ui_ObjectToClone.state of
        (
            1:(
                if isGroupHead fObj then cloneObj = fObj.children else cloneObj = fObj;
                layerName = fObj.layer.name;
                clonePos = startPoint;
                cloneVector = (endPoint - startPoint) / (dc_ui_Items.value + 1);
                rotX = (sRot.x - fRot.x)/(dc_ui_Items.value + 1);
                rotY = (sRot.y - fRot.y)/(dc_ui_Items.value + 1);
                rotZ = (sRot.z - fRot.z)/(dc_ui_Items.value + 1);
                )
            2:(
                if isGroupHead sObj then cloneObj = sObj.children else cloneObj = sObj;
                layerName = sObj.layer.name;
                clonePos = endPoint;
                cloneVector = (startPoint - endPoint) / (dc_ui_Items.value + 1);
                rotX = -(sRot.x - fRot.x)/(dc_ui_Items.value + 1);
                rotY = -(sRot.y - fRot.y)/(dc_ui_Items.value + 1);
                rotZ = -(sRot.z - fRot.z)/(dc_ui_Items.value + 1);
                )
            3:(
                if isValidNode dc_ui_PickObject.object then cloneObj = dc_ui_PickObject.object;
                else cloneObj = undefined;
                layerName = fObj.layer.name;
                clonePos = startPoint;
                cloneVector = (endPoint - startPoint) / (dc_ui_Items.value + 1);
                rotX = (sRot.x - fRot.x)/(dc_ui_Items.value + 1);
                rotY = (sRot.y - fRot.y)/(dc_ui_Items.value + 1);
                rotZ = (sRot.z - fRot.z)/(dc_ui_Items.value + 1);
                )
        )
        local tempClone;       
            case classOf cloneObj of
            (
                NodeChildrenArray:(
                    for i = 1 to dc_ui_Items.value do
                    (
                        clonePos += cloneVector;
                        case dc_ui_CloneType.selected of;
                        (
                            "复制": maxOps.cloneNodes cloneObj cloneType:#copy newNodes:&tempObj;
                            "关联": maxOps.cloneNodes cloneObj cloneType:#instance newNodes:&tempObj;
                            "参考": maxOps.cloneNodes cloneObj cloneType:#reference newNodes:&tempObj;
                        )
                        curGroup = tempObj[tempObj.count];
                        curGroup.pos = clonePos;
                        if mode == "Real" and dc_ui_KeepLayer.checked then;
                        (
                            dc_fn_MoveToLayer curGroup layerName;
                        )
                        if dc_ui_AlignClone.checked then;
                        (
                            in coordsys local curGroup.rotation = (eulerAngles (i*rotX) (i*rotY) (i*rotZ));
                        )
                        if mode == "Preview" then for obj in tempObj do;
                        (
                            if dc_ui_DisplayAsBox.state then obj.boxmode = true;
                            obj.isFrozen = true;
                        )
                        join dc_va_TempClone tempObj;
                    )
                )
                UndefinedClass:(
                    tempClone = undefined;
                    dc_va_TempClone = #();
                )
                default:(
                    for i = 1 to dc_ui_Items.value do
                    (
                        clonePos += cloneVector;
                        tempObj = case dc_ui_CloneType.selected of(
                            "复制": copy cloneObj;
                            "关联": instance cloneObj;
                            "参考": reference cloneObj;
                        )
                        try (
                            tempObj.controller = case dc_ui_ControllerType.selected of 
                            (
                                "复制": copy cloneObj.controller
                                "关联": cloneObj.controller
                            )
                        )catch()
                        tempObj.pos = clonePos
                        if dc_ui_AlignClone.checked then(
                            in coordsys local tempObj.rotation = (eulerAngles (i*rotX) (i*rotY) (i*rotZ));
                        )
                        if mode == "Preview" then(
                            if dc_ui_DisplayAsBox.state then tempObj.boxmode = true;
                            tempObj.isFrozen = true;
                        )
                        append dc_va_TempClone tempObj;
                        if mode == "Real" and dc_ui_KeepLayer.checked then;
                        (
                            dc_fn_MoveToLayer tempObj layerName;
                        )
                    )
                )
            )       
        try delete tempClone catch();
        dc_va_TempClone;
    )
    else dc_fn_ClearTemp();
    fn dc_fn_ShowPreview = if dc_ui_ShowPreview.state then dc_ui_Clone "Preview" else dc_fn_ClearTemp();
    fn dc_fn_CalcSpacing =(
        dc_fn_SafePreview();
        totalDis = dc_va_Distance - dc_ui_StartOffset.value - dc_ui_EndOffset.value;
        dc_ui_Spacing.value = totalDis / (dc_ui_Items.value + 1);
        dc_fn_ShowPreview();
    )
    fn dc_fn_CallBack =(
        dc_va_OrgObject = for obj in selection where (not isGroupMember obj or (isGroupHead obj and isOpenGroupMember obj) or isOpenGroupMember obj) collect obj;
        if dc_va_OrgObject.count == 2 then
        (
            dc_va_Distance = (distance dc_va_OrgObject[1].pos dc_va_OrgObject[2].pos);
            dc_fn_CalcSpacing();
        )
        else dc_fn_ClearTemp()
    )
    on dc_ui_ObjectToClone changed newState do(
        if newState == 3 then;
        (;
        if (dc_ui_PickObject.object != undefined and dc_ui_ShowPreview.state) then dc_ui_Clone "Preview" else dc_fn_ClearTemp();
        dc_ui_PickObject.enabled = true;
        );
        else;
        (;
        if dc_ui_ShowPreview.state then dc_ui_Clone "Preview";
        dc_ui_PickObject.enabled = false;
        );
    )
    on dc_ui_PickObject picked newObj do if newObj != undefined then(
        if (newObj.name).count > 7 then dc_ui_PickObject.text = (substring newObj.name 1 5) + "...";
        else dc_ui_PickObject.text = newObj.name;
        dc_ui_PickObject.tooltip = newObj.name;
        if dc_ui_ShowPreview.state then dc_ui_Clone "Preview";
    )
    on dc_ui_PickObject rightClick do(
        dc_va_OrgObject[3] = undefined;
        dc_ui_PickObject.text = "选择";
        dc_ui_PickObject.tooltip = "";
        dc_fn_ClearTemp();
    )
    on dc_ui_AlignClone changed newState do dc_fn_ShowPreview();
    on dc_ui_Items changed newValue do dc_fn_CalcSpacing();
    on dc_ui_Spacing changed newValue do(
        dc_ui_Items.value = (dc_va_Distance / newValue) - 1;
        dc_fn_SafePreview();
        totalDis = (dc_ui_Items.value + 1) * newValue;
        dc_ui_StartOffset.value = dc_ui_EndOffset.value = (dc_va_Distance - totalDis)/2;
        if dc_ui_ShowPreview.state then dc_ui_Clone "Preview";
    )
    on dc_ui_StartOffset changed newValue do dc_fn_CalcSpacing();
    on dc_ui_EndOffset changed newValue do dc_fn_CalcSpacing();
    on dc_ui_ShowPreview changed newState do(
        dc_fn_SafePreview();
        dc_fn_ShowPreview();
    )
    on dc_ui_RefreshPreview pressed do(
        dc_fn_SafePreview();
        dc_fn_ShowPreview();
    )
    on dc_ui_DisplayAsBox changed newState do dc_fn_ShowPreview();
    on dc_ui_ItemLimitEnable changed newState do(
        dc_ui_ItemLimitValue.enabled = newState;
        dc_fn_SafePreview();
        dc_fn_ShowPreview();
    )
    on dc_ui_StartClone pressed do(
            local outputArr = dc_ui_Clone "Real";
            dc_va_TempClone = #();
            select outputArr;
    )
    fn dc_fn_LoadSettings =(
        dc_ui_CloneType.selection = dc_fn_GetSetting "dc_ui_CloneType" as integer;
        dc_ui_ControllerType.selection = dc_fn_GetSetting "dc_ui_ControllerType" as integer;
        dc_ui_Items.value = dc_fn_GetSetting "dc_ui_Items" as integer;
        dc_ui_StartOffset.value = dc_fn_GetSetting "dc_ui_StartOffset" as float;
        dc_ui_EndOffset.value = dc_fn_GetSetting "dc_ui_EndOffset" as float;
        dc_ui_ShowPreview.checked = dc_fn_GetSetting "dc_ui_ShowPreview" == "true";
        dc_ui_DisplayAsBox.checked = dc_fn_GetSetting "dc_ui_DisplayAsBox" == "true";
        dc_ui_ItemLimitValue.value = dc_fn_GetSetting "dc_ui_ItemLimitValue" as integer;
        dc_ui_ItemLimitEnable.checked = dc_fn_GetSetting "dc_ui_ItemLimitEnable" == "true";
        dc_ui_AlignClone.checked = dc_fn_GetSetting "dc_ui_AlignClone" == "true";
        dc_ui_KeepLayer.checked = dc_fn_GetSetting "dc_ui_KeepLayer" == "true";
        dc_ui_CloneType.enabled = dc_ui_ControllerType.enabled = true;
        dc_ui_PickObject.enabled = false;
        dc_ui_ItemLimitValue.enabled = dc_ui_ItemLimitEnable.checked;
    )
    fn dc_fn_SaveSettings =(
        dc_fn_SetSetting "dc_ui_AlignClone" dc_ui_AlignClone.checked;
        dc_fn_SetSetting "dc_ui_KeepLayer" dc_ui_KeepLayer.checked;
        dc_fn_SetSetting "dc_ui_CloneType" dc_ui_CloneType.selection;
        dc_fn_SetSetting "dc_ui_ControllerType" dc_ui_ControllerType.selection;
        dc_fn_SetSetting "dc_ui_Items" dc_ui_Items.value;
        dc_fn_SetSetting "dc_ui_StartOffset" dc_ui_StartOffset.value;
        dc_fn_SetSetting "dc_ui_EndOffset" dc_ui_EndOffset.value;
        dc_fn_SetSetting "dc_ui_ShowPreview" dc_ui_ShowPreview.checked;
        dc_fn_SetSetting "dc_ui_DisplayAsBox" dc_ui_DisplayAsBox.checked;
        dc_fn_SetSetting "dc_ui_ItemLimitValue" dc_ui_ItemLimitValue.value;
        dc_fn_SetSetting "dc_ui_ItemLimitEnable" dc_ui_ItemLimitEnable.checked;
    )
    on dc_ro_MainScript open do(
        dc_fn_LoadSettings();
        dc_fn_CallBack();
        callbacks.addScript #selectionSetChanged "dc_ro_MainScript.dc_fn_CallBack()" id:#dc_cb_FilterSelection;
        callbacks.addScript #postNodeSelectOperation "dc_ro_MainScript.dc_fn_CallBack()" id:#dc_cb_FilterSelection;
    )
    on dc_ro_MainScript close do(
        dc_fn_ClearTemp();
        dc_fn_SaveSettings();
        try callbacks.removeScripts id:#dc_cb_FilterSelection catch();
    )
)
dc_va_OrgObject = for obj in selection where (not isGroupMember obj or (isGroupHead obj and isOpenGroupMember obj) or isOpenGroupMember obj) collect obj;
createDialog dc_ro_MainScript;
clearListener()
