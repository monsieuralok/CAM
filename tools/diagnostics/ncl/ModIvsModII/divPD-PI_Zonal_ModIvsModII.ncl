  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
  load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"

begin

; This ncl script reads in various 3d fields from two versions of NorESM/CAM-Oslo 
; (PD and PI) and makes global plots of the anthropogenic (PD-PI) zonally and 
; annually averaged variables. 

; Model independent constants
 g=9.80665
 pi=3.1415926
 re=6378.39e3            ; earth radius in m
 coffa=pi*re^2./180.      
 area1=4.*pi*re^2          
 small=1.0e-15           ; small number

; *************************************************************************
; **** To be edited by the user if the ncl script is run interactively ****
;
; Define plot type and plot output format
 if (.not. isvar("plot_type")) then      ; is plot_type on command line?
  plot_type = 4                      ; 0 => CLOUD   Cloud fraction
                                     ; 1 => RH      Relative humidity RELHUM
                                     ; 2 => CLDLIQ  Cloud liquid amount 
                                     ; 3 => CLDICE  Cloud ice amount
                                     ; 4 => RHW     Relative humidity RHW
                                     ; 5 => CDNC    Cloud droplet number concentration
                                     ; 6 => REFFL   Cloud droplet effective radius
; *************************************************************************
 end if
 if (.not. isvar("format")) then        ; is format on command line?
  format = "ps"
;  format = "eps"
;  format = "png"
;  format = "pdf"
 end if
;
; *************************************************************************
; No changes by the user should be necessary below...
; *************************************************************************
;old  all_files_I  = systemfunc ("ls /media/BackupAK/aerocomA2r128-tester/CTRL2000/aerocomA2r128_2006.cam2.h0.0007-*.nc")
      all_filesPD_I  = systemfunc ("ls " + filepathPD_I + filenamepPD_I + "*")
      all_filesPD_II = systemfunc ("ls " + filepathPD_II + filenamepPD_II + "*")
      f0PD_I      = addfile (filepathPD_I+filenamePD_I, "r")
      f0PD_II     = addfile (filepathPD_II+filenamePD_II, "r")
      f1PD_I      = addfiles (all_filesPD_I, "r")   ; note the "s" of addfile
      f1PD_II     = addfiles (all_filesPD_II, "r")   ; note the "s" of addfile
      all_filesPI_I  = systemfunc ("ls " + filepathPI_I + filenamepPI_I + "*")
      all_filesPI_II = systemfunc ("ls " + filepathPI_II + filenamepPI_II + "*")
      f1PI_I      = addfiles (all_filesPI_I, "r")   ; note the "s" of addfile
      f1PI_II     = addfiles (all_filesPI_II, "r")   ; note the "s" of addfile

 if (plot_type.eq.0) then
 var="CLOUD"                     ; name of input-variable
 varname="CLOUD"                 ; variable name used in text string
 plot_name="dCLOUD_Zonal"         ; name of the plot/figure
 var_I  = 1.e2*(/(f1PD_I[:]->CLOUD)/) - 1.e2*(/(f1PI_I[:]->CLOUD)/)
 var_II  = 1.e2*(/(f1PD_II[:]->CLOUD)/) - 1.e2*(/(f1PI_II[:]->CLOUD)/)
 else if (plot_type.eq.1) then
 var="RELHUM"                    ; name of input-variable and plot
 varname="RH"                    ; variable name used in text string
 plot_name="dRELHUM_Zonal"        ; name of the plot/figure
 var_I  = (/(f1PD_I[:]->RELHUM)/) - (/(f1PI_I[:]->RELHUM)/)
 var_II  = (/(f1PD_II[:]->RHW)/) - (/(f1PI_II[:]->RHW)/)
 else if (plot_type.eq.2) then
 var="CLDLIQ"                    ; name of input-variable and plot
 varname="Cloud liquid amount"   ; variable name used in text string
 plot_name="dCLDLIQ_Zonal"        ; name of the plot/figure
 if(ModI.eq."CAM4-Oslo") then
  var_I=1.e6*(/(f1PD_I[:]->CLDLIX)/) - 1.e6*(/(f1PI_I[:]->CLDLIX)/)    ; if CAM4-Oslo only
 else
  var_I=1.e6*(/(f1PD_I[:]->CLDLIQ)/) - 1.e6*(/(f1PI_I[:]->CLDLIQ)/)
 end if
 var_II=1.e6*(/(f1PD_II[:]->CLDLIQ)/) - 1.e6*(/(f1PI_II[:]->CLDLIQ)/)
 else if (plot_type.eq.3) then
 var="CLDICE"                    ; name of input-variable and plot
 varname="Cloud ice amount"      ; variable name used in text string
 plot_name="dCLDICE_Zonal"        ; name of the plot/figure
 var_I=1.e6*(/(f1PD_I[:]->CLDICE)/) - 1.e6*(/(f1PI_I[:]->CLDICE)/)
 var_II=1.e6*(/(f1PD_II[:]->CLDICE)/) - 1.e6*(/(f1PI_II[:]->CLDICE)/)
 else if (plot_type.eq.4) then
 var="RELHUM"                    ; name of input-variable and plot
 varname="RH"                    ; variable name used in text string
 plot_name="dRHW_Zonal"           ; name of the plot/figure
 if(ModI.eq."CAM4-Oslo") then
  var_I  = (/(f1PD_I[:]->RELHUM)/) - (/(f1PI_I[:]->RELHUM)/)
 else
  var_I  = (/(f1PD_I[:]->RHW)/) - (/(f1PI_I[:]->RHW)/)
 end if
 var_II  = (/(f1PD_II[:]->RHW)/) - (/(f1PI_II[:]->RHW)/)
 else if (plot_type.eq.5) then
 var="CDNC"                      ; name of plot
 varname="CDNC"                  ; variable name used in text string
 plot_name="dCDNC_Zonal"          ; name of the plot/figure
 if(ModI.eq."CAM4-Oslo") then
  var_I = (/(f1PD_I[:]->CLOUD)/)*(/(f1PD_I[:]->CDNC)/)/((/(f1PD_I[:]->CLDFOC)/)+small) - (/(f1PI_I[:]->CLOUD)/)*(/(f1PI_I[:]->CDNC)/)/((/(f1PI_I[:]->CLDFOC)/)+small)
 else
 var_I = 1.e-6*(/(f1PD_I[:]->AWNC)/)/((/(f1PD_I[:]->FREQL)/)+small) - 1.e-6*(/(f1PI_I[:]->AWNC)/)/((/(f1PI_I[:]->FREQL)/)+small)
 end if
 var_II = 1.e-6*(/(f1PD_II[:]->AWNC)/)/((/(f1PD_II[:]->FREQL)/)+small) - 1.e-6*(/(f1PI_II[:]->AWNC)/)/((/(f1PI_II[:]->FREQL)/)+small)
 else if (plot_type.eq.6) then
 var="REFFL"                      ; name of plot
 varname="REFFL"                  ; variable name used in text string
 plot_name="dREFFL_Zonal"          ; name of the plot/figure
 if(ModI.eq."CAM4-Oslo") then
  var_I=(/(f1PD_I[:]->REFFL)/)/((/(f1PD_I[:]->CLDFOC)/)+small) - (/(f1PI_I[:]->REFFL)/)/((/(f1PI_I[:]->CLDFOC)/)+small)
 else
  var_I=(/(f1PD_I[:]->AREL)/)/((/(f1PD_I[:]->FREQL)/)+small) - (/(f1PI_I[:]->AREL)/)/((/(f1PI_I[:]->FREQL)/)+small)
 end if
  var_II=(/(f1PD_II[:]->AREL)/)/((/(f1PD_II[:]->FREQL)/)+small) - (/(f1PI_II[:]->AREL)/)/((/(f1PI_II[:]->FREQL)/)+small)
 end if
 end if
 end if
 end if
 end if
 end if
 end if
; printVarSummary(var_I)
; printVarSummary(var_II)

;lat_I = f0_I->lat                                  ; pull lat off file
;lat_II = f0_II->lat                                ; pull lat off file
lat_I = f0PD_I->lat                                  ; pull lat off file
lat_II = f0PD_II->lat                                ; pull lat off file
;************************************************
;  calculate eta
;************************************************
   a=f0PD_I->hyam                                    ; select hyam 
   b=f0PD_I->hybm                                    ; select hybm
   p=f0PD_I->P0                                      ; select P0
   eta = (a+b)*p                                   ; calc eta
   eta_I = eta/100                                 ; scale eta by 100
   a_II=f0PD_II->hyam                                ; select hyam 
   b_II=f0PD_II->hybm                                ; select hybm
   p_II=f0PD_II->P0                                  ; select P0
   eta_II = (a_II+b_II)*p                          ; calc eta
   eta_II = eta_II/100                             ; scale eta by 100

; zave_I = dim_avg_Wrap(var_I)    ; calculate zonal ave
; zave_II = dim_avg_Wrap(var_II)  ; calculate zonal ave
 zave_I = dim_avg_Wrap(var_I)
 zave_II = dim_avg_Wrap(var_II)
; printVarSummary(zave_I)
; printVarSummary(zave_II)

; Defining color scales for each meteorology variable
if (var.eq."CLOUD") then
 digg=(/-1,-.5,-.1,0,0.1,0.5,1/)
 else if (var .eq. "RELHUM") then
  digg=(/-1,-.5,-.1,0,0.1,0.5,1/)
   else if (var .eq. "CLDLIQ") then
    digg=(/-.1,0,0.1,0.5,1,2,3/)
     else if (var .eq. "CLDICE") then
      digg=(/-0.2,-0.1,-0.05,0,0.05,0.1,0.2/)
       else if (var .eq. "CDNC") then
        digg=(/-.5,-0.1,0,0.1,0.5,1,2.5,5,10,15/)
         else if (var .eq. "REFFL") then
          digg=(/-1,-.5,-.1,0,0.1,0.5,1/)
         else
          digg=(/0.0,1.0/)                         ; Replace with error message
         end if
       end if
      end if
    end if
  end if
end if

;;;;;;;;;;;;;;;;;;;;;;;;;
;
;    Make the Plot
;
;;;;;;;;;;;;;;;;;;;;;;;;;

;if (plot_type.eq.4) then
;  wks = gsn_open_wks(format,"RHW")
;else
;  wks = gsn_open_wks(format,var)
  wks = gsn_open_wks(format,plot_name)
;end if

  gsn_define_colormap(wks,"amwg_blueyellowred")
;  gsn_define_colormap(wks,"BlueDarkRed18")
;  gsn_define_colormap(wks,"precip2_15lev")
;  gsn_define_colormap(wks,"gui_default")
;  gsn_define_colormap(wks,"hotres")
  plot=new(2,graphic)
  
  res                   = True                  ; plot mods desired
  res@gsnSpreadColors   = False                 ; use full colormap
;  res@mpFillOn          = False                 
  res@cnFillOn          = True                  ; color fill 
  res@cnLinesOn         = False                 ; no contour lines
  res@cnLineLabelsOn    = False                 
  res@gsnFrame          = False                 ; Do not draw plot
  res@gsnDraw           = False                 ; Do not advance frame
;  res@lbLabelBarOn      = False 
;  res@tmXBOn =False
;  res@tmXTOn =False
;  res@tmYLOn =False
;  res@tmYROn =False
  res@cnMissingValFillPattern = 0
  res@cnMissingValFillColor = 16
  res@tiMainFontHeightF = 0.03
  res@tiMainFontThicknessF = 2
;  res@txFontHeightF       = 0.02
;  res@cnFillMode        = "RasterFill"  ; Turn on raster fill
  res@tiMainFont = "helvetica"
  res@tmYRMode             = "Automatic"
  res@cnInfoLabelOn        = False
  res@cnLevelSelectionMode      = "ExplicitLevels"       ; manual levels

  res@sfYArray              = eta_I                  ; use eta for y axis
  res@sfXArray              = lat_I                  ; use lat for x axis
  res@tiXAxisString         = "latitude"           ; x-axis label
  res@tiYAxisString         = "eta x 1000"         ; y-axis label
  res@trXReverse            = False                ; reverse x-axis
  res@trYReverse            = True                 ; reverse y-axis
;  res@gsnYAxisIrregular2Log = True                 ; set y-axis to log scale

  res@cnFillColors   = (/3,5,6,8,9,10,11,12,13,14,15,16/) 
  res@cnLevels       =   sprintf("%7.5f",digg)             ; min level

  res2                   = True                  ; plot mods desired
  res2@gsnSpreadColors   = False                 ; use full colormap
;  res2@mpFillOn          = False                 
  res2@cnFillOn          = True                  ; color fill 
  res2@cnLinesOn         = False                 ; no contour lines
  res2@cnLineLabelsOn    = False                 
  res2@gsnFrame          = False                 ; Do not draw plot
  res2@gsnDraw           = False                 ; Do not advance frame
;  res2@lbLabelBarOn      = False 
;  res2@tmXBOn =False
;  res2@tmXTOn =False
;  res2@tmYLOn =False
;  res2@tmYROn =False
  res2@cnMissingValFillPattern = 0
  res2@cnMissingValFillColor = 16
  res2@tiMainFontHeightF = 0.03
  res2@tiMainFontThicknessF = 2
;  res2@txFontHeightF       = 0.02
;  res2@cnFillMode        = "RasterFill"  ; Turn on raster fill
  res2@tiMainFont = "helvetica"
  res2@tmYRMode             = "Automatic"
  res2@cnInfoLabelOn        = False
  res2@cnLevelSelectionMode      = "ExplicitLevels"       ; manual levels

  res2@sfYArray              = eta_II                  ; use eta for y axis
  res2@sfXArray              = lat_II                  ; use lat for x axis
  res2@tiXAxisString         = "latitude"           ; x-axis label
  res2@tiYAxisString         = "eta x 1000"         ; y-axis label
  res2@trXReverse            = False                ; reverse x-axis
  res2@trYReverse            = True                 ; reverse y-axis
;  res2@gsnYAxisIrregular2Log = True                 ; set y-axis to log scale

  res2@cnFillColors   = (/3,5,6,8,9,10,11,12,13,14,15,16/) 
  res2@cnLevels       =   sprintf("%7.5f",digg)             ; min level

if (var .eq. "CLOUD") then
  res@tiMainString  = "Cloud Fraction (%)"
else if (var .eq. "RELHUM") then
 if (plot_type.eq.4) then
  if(ModI.eq."CAM4-Oslo") then
   res@tiMainString  = "Relative Humidity RELHUM (%)"
  else
   res@tiMainString  = "Relative Humidity RHW (%)"
  end if
 else
  if(ModI.eq."CAM4-Oslo") then
   res@tiMainString  = "Relative Humidity RELHUM (%)"
  else
   res@tiMainString  = "Relative Humidity RELHUM (%)" 
  end if
 end if
else if (var .eq. "CLDLIQ") then
  res@tiMainString  = "Cloud Liquid Water (mg kg~S~-1~N~)"
else if (var .eq. "CLDICE") then
  res@tiMainString  = "Cloud Ice (mg kg~S~-1~N~)"
else if (var .eq. "CDNC") then
 if(ModI.eq."CAM4-Oslo") then
;  res@tiMainString  = "CDNC (CLDTOT*CDNC/CLDFOC) (cm~S~-3~N~)"
  res@tiMainString  = "CDNC (CDNC/CLDFOC) (cm~S~-3~N~)"
 else
;  res@tiMainString  = "CDNC (AWNC) (cm~S~-3~N~)"
  res@tiMainString  = "CDNC (AWNC/FREQL) (cm~S~-3~N~)"
 end if
else if (var .eq. "REFFL") then
 if(ModI.eq."CAM4-Oslo") then
;  res@tiMainString  = "REFFL (CLDTOT*REFFL/CLDFOC) (~F33~m~F21~m)"
  res@tiMainString  = "REFFL (REFFL/CLDFOC) (~F33~m~F21~m)"
 else
;  res@tiMainString  = "REFFL (AREL) (~F33~m~F21~m)"
  res@tiMainString  = "REFFL (AREL/FREQL) (~F33~m~F21~m)"
 end if
end if
end if
end if
end if
end if
end if
  plot(0) = gsn_contour(wks,dim_avg_n_Wrap(zave_I,0),res)    ; create the plot

if (var .eq. "CLOUD") then
  res2@tiMainString  = "Cloud Fraction (%)"
else if (var .eq. "RELHUM") then
 if (plot_type.eq.4) then
  if(ModI.eq."CAM4-Oslo") then
   res2@tiMainString  = "Relative Humidity RHW (%)"
  else
   res2@tiMainString  = "Relative Humidity RHW (%)"
  end if
 else
  if(ModI.eq."CAM4-Oslo") then
   res2@tiMainString  = "Relative Humidity RELHUM (%)"
  else
   res2@tiMainString  = "Relative Humidity RELHUM (%)" 
  end if
 end if
else if (var .eq. "CLDLIQ") then
  res2@tiMainString  = "Cloud Liquid Water (mg kg~S~-1~N~)"
else if (var .eq. "CLDICE") then
  res2@tiMainString  = "Cloud Ice (mg kg~S~-1~N~)"
else if (var .eq. "CDNC") then
;  res2@tiMainString  = "CDNC (AWNC) (cm~S~-3~N~)"
  res2@tiMainString  = "CDNC (AWNC/FREQL) (cm~S~-3~N~)"
else if (var .eq. "REFFL") then
;  res2@tiMainString  = "REFFL (AREL) (~F33~m~F21~m)"
  res2@tiMainString  = "REFFL (AREL/FREQL) (~F33~m~F21~m)"
end if
end if
end if
end if
end if
end if
  plot(1) = gsn_contour(wks,dim_avg_n_Wrap(zave_II,0),res2)    ; create the plot

  pres                            = True        ; panel plot mods desired
;  pres@gsnMaximize                = True        ; fill the page
;  pres@txString   =   var
  pres@txFontHeightF              =0.015
  pres@txFontThicknessF              =2
  pres@gsnPanelLabelBar = True
  pres@lbLabelFontHeightF = 0.01
  pres@lbOrientation        ="Vertical"

  gsn_panel(wks,plot,(/1,2/),pres)              ; create panel plot

end

