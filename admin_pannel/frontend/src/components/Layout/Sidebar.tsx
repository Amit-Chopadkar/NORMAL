/**
 * Sidebar navigation with Recent Reports
 */

import React from 'react';

interface SidebarProps {
    isOpen: boolean;
    onClose: () => void;
}

const Sidebar: React.FC<SidebarProps> = ({ isOpen, onClose }) => {
    return (
        <>
            {/* Mobile overlay */}
            {isOpen && (
                <div
                    className="fixed inset-0 bg-black bg-opacity-50 z-20 lg:hidden"
                    onClick={onClose}
                />
            )}

            {/* Sidebar */}
            <aside
                className={`fixed lg:static inset-y-0 left-0 w-64 bg-navy-light border-r border-gray-700 z-30 transform transition-transform duration-300 ${isOpen ? 'translate-x-0' : '-translate-x-full'
                    } lg:translate-x-0`}
            >
                <div className="p-6">
                    {/* <h2 className="text-lg font-semibold text-white mb-4">Menu</h2> */}
                    <nav className="space-y-2">
                        <p
                            // href="#dashboard"
                            className="block px-4 py-2 bg-danger text-white rounded cursor:default"
                        >
                            🏠 Dashboard
                        </p>
                        {/* <a
                            href="#recent-reports"
                            className="block px-4 py-2 text-gray-300 rounded hover:bg-navy"
                        >
                            📋 Recent Reports
                        </a> */}
                    </nav>

                    {/* Recent SOS Events Summary */}
                    <div className="mt-6 p-4 bg-navy rounded-lg">
                        <h3 className="text-sm font-semibold text-gray-300 mb-3">Recent Activity</h3>
                        <div className="space-y-2 text-xs text-gray-400">
                            <div className="flex justify-between">
                                <span>Pending</span>
                                <span className="badge-pending text-[10px]">LIVE</span>
                            </div>
                            <div className="flex justify-between">
                                <span>Acknowledged</span>
                                <span className="text-warning font-semibold">Active</span>
                            </div>
                            <div className="flex justify-between">
                                <span>Resolved Today</span>
                                <span className="text-success font-semibold">Done</span>
                            </div>
                        </div>
                    </div>

                    {/* App Registration Info */}
                    <div className="mt-4 p-3 bg-navy-dark rounded text-xs text-gray-400">
                        <div className="flex items-center space-x-2">
                            <svg className="w-4 h-4 text-info" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                            </svg>
                            <span>Real-time from mobile app</span>
                        </div>
                    </div>
                </div>
            </aside>
        </>
    );
};

export default Sidebar;
