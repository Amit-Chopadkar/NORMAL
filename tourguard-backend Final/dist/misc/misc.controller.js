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
Object.defineProperty(exports, "__esModule", { value: true });
exports.MiscController = void 0;
const common_1 = require("@nestjs/common");
const jwt_auth_guard_1 = require("../auth/jwt-auth.guard");
let MiscController = class MiscController {
    getSafetyScore() {
        return {
            score: 87,
            level: 'good',
            factors: {
                locationAwareness: 90,
                incidentReports: 85,
                emergencyPreparedness: 88,
                communityEngagement: 84,
            },
            tips: [
                'Keep emergency contacts updated',
                'Enable location sharing during trips',
                'Report incidents to help others',
            ],
        };
    }
    getProfile() {
        return {
            id: '1',
            name: 'Tourist User',
            email: 'user@example.com',
            phone: '+1234567890',
            memberSince: '2024-01-01',
            tripsCompleted: 12,
            incidentsReported: 3,
            safetyScore: 87,
        };
    }
    getPlaces() {
        return [
            {
                id: '1',
                name: 'Historical Monument',
                category: 'tourist_attraction',
                safetyLevel: 'high',
                rating: 4.5,
                location: { lat: 28.6129, lng: 77.2295 },
                description: 'Famous historical site',
            },
            {
                id: '2',
                name: 'Local Market',
                category: 'shopping',
                safetyLevel: 'medium',
                rating: 4.0,
                location: { lat: 28.6139, lng: 77.2090 },
                description: 'Traditional marketplace',
            },
            {
                id: '3',
                name: 'City Park',
                category: 'recreation',
                safetyLevel: 'high',
                rating: 4.7,
                location: { lat: 28.6149, lng: 77.2195 },
                description: 'Beautiful city park',
            },
        ];
    }
};
exports.MiscController = MiscController;
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('safety-score'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], MiscController.prototype, "getSafetyScore", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('profile'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], MiscController.prototype, "getProfile", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard),
    (0, common_1.Get)('places'),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], MiscController.prototype, "getPlaces", null);
exports.MiscController = MiscController = __decorate([
    (0, common_1.Controller)('api')
], MiscController);
