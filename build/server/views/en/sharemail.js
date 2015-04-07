var jade = require('jade/runtime');
module.exports = function template(locals) {
var buf = [];
var jade_mixins = {};
var jade_interp;
;var locals_for_with = (locals || {});(function (displayName, doc, localization, rule, type, url) {
buf.push("<!DOCTYPE html><html><head><meta name=\"viewport\" content=\"width=device-width\"><meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\"></head><body><table cellspacing=\"0\" style=\"border-radius: 5px; border: 5px solid #34A6FF; margin: auto; width: 75%; padding: 20px 20px 10px 20px\"><tr><th style=\"color: #34A6FF; font-size: 20px\">" + (jade.escape((jade_interp = displayName) == null ? '' : jade_interp)) + " shared the \"" + (jade.escape((jade_interp = doc.name) == null ? '' : jade_interp)) + "\" " + (jade.escape((jade_interp = localization.t(type)) == null ? '' : jade_interp)) + " with you!</th></tr><tr><td style=\"padding: 45px 0; text-align: center; font-size: 18px\"><a" + (jade.attr("href", url, true, true)) + " style=\"background: #34A6FF; color: #fff; padding: 8px; border-radius: 5px; text-decoration: none;\">" + (jade.escape((jade_interp = localization.t('link ' + type + ' content')) == null ? '' : jade_interp)) + ".</a></td></tr>");
if ( type == 'folder')
{
buf.push("<tr><td>You can:<ul><li>Download files from this folder</li>");
if ( type == 'folder' && rule.perm == 'rw')
{
buf.push("<li>Add new files to this folder</li>");
}
buf.push("<li>Subscribe to change notifications of this folder</li></ul></td></tr>");
}
buf.push("<tr><td style=\"text-align: right; font-size: 12px; padding-top: 10px;\">Sent from " + (jade.escape((jade_interp = displayName) == null ? '' : jade_interp)) + "'s&nbsp;<a href=\"http://cozy.io\" style=\"color: #34A6FF;\">Cozy</a>.</td></tr></table></body></html>");}.call(this,"displayName" in locals_for_with?locals_for_with.displayName:typeof displayName!=="undefined"?displayName:undefined,"doc" in locals_for_with?locals_for_with.doc:typeof doc!=="undefined"?doc:undefined,"localization" in locals_for_with?locals_for_with.localization:typeof localization!=="undefined"?localization:undefined,"rule" in locals_for_with?locals_for_with.rule:typeof rule!=="undefined"?rule:undefined,"type" in locals_for_with?locals_for_with.type:typeof type!=="undefined"?type:undefined,"url" in locals_for_with?locals_for_with.url:typeof url!=="undefined"?url:undefined));;return buf.join("");
}