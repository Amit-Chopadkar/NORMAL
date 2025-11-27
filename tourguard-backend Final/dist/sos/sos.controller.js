"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SosController = void 0;
const common_1 = require("@nestjs/common");
const class_validator_1 = require("class-validator");
class EmergencyContactDto {
}
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], EmergencyContactDto.prototype, "name", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    __metadata("design:type", String)
], EmergencyContactDto.prototype, "phone", void 0);
class SendSOSDto {
}
__decorate([
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], SendSOSDto.prototype, "latitude", void 0);
__decorate([
    (0, class_validator_1.IsNumber)(),
    __metadata("design:type", Number)
], SendSOSDto.prototype, "longitude", void 0);
__decorate([
    (0, class_validator_1.IsArray)(),
    __metadata("design:type", Array)
], SendSOSDto.prototype, "emergencyContacts", void 0);
__decorate([
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], SendSOSDto.prototype, "userName", void 0);
let SosController = class SosController {
    async sendSOS(dto) {
        console.log(`🚨 SOS ALERT: ${dto.userName || 'Unknown'} at ${dto.latitude}, ${dto.longitude}`);
        console.log(`📞 Notifying ${dto.emergencyContacts.length} emergency contacts`);
        return {
            success: true,
            message: 'SOS alert sent successfully',
            alertId: `sos_${Date.now()}`,
            timestamp: new Date().toISOString(),
        };
    }
};
exports.SosController = SosController;
__decorate([
    (0, common_1.Post)('send'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [SendSOSDto]),
    __metadata("design:returntype", Promise)
], SosController.prototype, "sendSOS", null);
exports.SosController = SosController = __decorate([
    (0, common_1.Controller)('api/sos')
], SosController);
