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
        { icon: '🚔', name: 'Police Station', distance: '0.8 km', action: 'DISPATCH', actionClass: 'bg-success', latitude: 19.0760, longitude: 72.8777, phone: '112' },
        { icon: '🚔', name: 'Central Police Zone', distance: '0.8 km', action: 'CONTACT', actionClass: 'bg-success', phone: '+91-22-2262-0111' },
        { icon: '🏥', name: 'City General Hospital', distance: '1.2 km', action: 'CONTACT', actionClass: 'bg-success', phone: '+91-22-2373-5555' },
        { icon: '🚒', name: 'Fire Station', distance: '0.5 km', action: 'CONTACT', actionClass: 'bg-success', phone: '101' },
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
