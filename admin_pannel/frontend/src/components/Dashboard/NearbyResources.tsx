/**
 * Nearby emergency resources panel
 */

import React from 'react';
import { SosEvent } from '../../types';
import toast from 'react-hot-toast';

interface Resource {
    icon: string;
    name: string;
    distance: string;
    action: string;
    actionClass: string;
    phone?: string;
    latitude?: number;
    longitude?: number;
}

interface NearbyResourcesProps {
    event?: SosEvent | null;
}

const NearbyResources: React.FC<NearbyResourcesProps> = ({ event }) => {
    const resources: Resource[] = [
        // Law Enforcement
        { icon: '🚔', name: 'Police Station', distance: '0.8 km', action: 'DISPATCH', actionClass: 'bg-success', latitude: 19.0760, longitude: 72.8777, phone: '112' },
        { icon: '🚔', name: 'Central Police Zone', distance: '0.8 km', action: 'CONTACT', actionClass: 'bg-success', phone: '+91-364-2222-644' },
        { icon: '👮', name: 'Tourist Police', distance: '1.0 km', action: 'CONTACT', actionClass: 'bg-success', phone: '1800-345-3644' },
        
        // Medical Services
        { icon: '🏥', name: 'Civil Hospital Shillong', distance: '1.2 km', action: 'CONTACT', actionClass: 'bg-success', phone: '+91-364-2223-105' },
        { icon: '🚑', name: 'Ambulance (Emergency)', distance: '0.9 km', action: 'CONTACT', actionClass: 'bg-danger', phone: '108' },
        { icon: '⚕️', name: 'NEIGRIHMS Hospital', distance: '2.5 km', action: 'CONTACT', actionClass: 'bg-success', phone: '+91-364-2538-011' },
        
        // Fire & Rescue
        { icon: '🚒', name: 'Fire Station', distance: '0.5 km', action: 'CONTACT', actionClass: 'bg-danger', phone: '101' },
        { icon: '🚨', name: 'Fire Emergency', distance: '0.5 km', action: 'CONTACT', actionClass: 'bg-danger', phone: '+91-364-2224-202' },
        
        // Military & Defense
        { icon: '🪖', name: 'Indian Army (Assam Rifles)', distance: '3.2 km', action: 'CONTACT', actionClass: 'bg-warning', phone: '+91-364-2501-234' },
        { icon: '⚔️', name: 'Military Hospital', distance: '3.8 km', action: 'CONTACT', actionClass: 'bg-warning', phone: '+91-364-2570-285' },
        
        // Disaster Management
        { icon: '🆘', name: 'SDRM (State Disaster Response)', distance: '1.5 km', action: 'CONTACT', actionClass: 'bg-danger', phone: '+91-364-2226-244' },
        { icon: '🚁', name: 'NDRF (National Disaster Response)', distance: '4.0 km', action: 'CONTACT', actionClass: 'bg-danger', phone: '011-2671-9395' },
        { icon: '⚠️', name: 'Disaster Management Control Room', distance: '1.8 km', action: 'CONTACT', actionClass: 'bg-danger', phone: '1070' },
        
        // Forest & Wildlife
        { icon: '🌲', name: 'Forest Department', distance: '2.0 km', action: 'CONTACT', actionClass: 'bg-success', phone: '+91-364-2222-206' },
        { icon: '🐘', name: 'Wildlife Emergency', distance: '2.5 km', action: 'CONTACT', actionClass: 'bg-success', phone: '+91-364-2501-640' },
        
        // Women & Child Safety
        { icon: '👩', name: 'Women Helpline', distance: 'Statewide', action: 'CONTACT', actionClass: 'bg-purple-600', phone: '1091' },
        { icon: '👶', name: 'Child Helpline', distance: 'Statewide', action: 'CONTACT', actionClass: 'bg-purple-600', phone: '1098' },
    ];

    const handleAction = (resource: Resource) => {
        if (resource.action === 'DISPATCH' && resource.latitude && resource.longitude) {
            // Open Google Maps for navigation
            const url = `https://www.google.com/maps/dir/?api=1&destination=${resource.latitude},${resource.longitude}`;
            window.open(url, '_blank');
            toast.success(`Dispatching to ${resource.name}`);
        } else if (resource.action === 'CONTACT' && resource.phone) {
            // Show phone number with option to call
            toast((t) => (
                <div>
                    <p className="font-semibold">{resource.name}</p>
                    <p className="text-sm">{resource.phone}</p>
                    <a
                        href={`tel:${resource.phone}`}
                        className="text-blue-500 hover:underline text-sm"
                        onClick={() => toast.dismiss(t.id)}
                    >
                        Call Now
                    </a>
                </div>
            ), { duration: 5000 });
        }
    };

    return (
        <div className="card h-full flex flex-col">
            <h3 className="font-semibold text-white mb-4 shrink-0">
                {event ? 'NEARBY HELP & RESOURCES' : 'EMERGENCY RESOURCES'}
            </h3>

            {/* Show event location if selected */}
            {event && (
                <div className="mb-3 p-2 bg-navy-dark rounded shrink-0">
                    <p className="text-xs text-gray-400">Event Location</p>
                    <p className="text-white text-sm font-mono">
                        {event.latitude.toFixed(6)}, {event.longitude.toFixed(6)}
                    </p>
                </div>
            )}

            <div className="space-y-2 overflow-y-auto flex-1 pr-2 custom-scrollbar">
                {resources.map((resource, idx) => (
                    <div
                        key={idx}
                        className="flex items-center justify-between p-3 bg-navy rounded-lg hover:bg-navy-dark transition-all duration-200 hover:shadow-lg border border-gray-700 hover:border-gray-600"
                    >
                        <div className="flex items-center flex-1">
                            <span className="text-2xl mr-3">{resource.icon}</span>
                            <div className="flex-1">
                                <p className="text-white text-sm font-semibold">{resource.name}</p>
                                {resource.distance && (
                                    <p className="text-gray-400 text-xs mt-0.5">📍 {resource.distance}</p>
                                )}
                            </div>
                        </div>
                        {resource.action && (
                            <button
                                onClick={() => handleAction(resource)}
                                className={`${resource.actionClass} text-white text-xs px-4 py-2 rounded-md hover:opacity-90 transition-all font-semibold shadow-md hover:shadow-lg flex items-center gap-1`}
                            >
                                {resource.action === 'DISPATCH' ? '🚀' : '📞'} {resource.action}
                            </button>
                        )}
                    </div>
                ))}
            </div>
        </div>
    );
};

export default NearbyResources;
