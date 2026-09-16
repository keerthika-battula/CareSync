import React, { useState, useEffect, useRef } from 'react';
import { 
  FileText, Upload, Download, Trash2, Search, Filter, 
  RefreshCw, FileCheck, FileCode, HardDrive, User, Plus 
} from 'lucide-react';
import { Card, CardHeader, CardTitle, CardDescription, CardContent } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Select } from '@/components/ui/Select';
import { Badge } from '@/components/ui/Badge';
import { Modal } from '@/components/ui/Modal';
import { useToast } from '@/context/ToastContext';
import { documentsApi, familyApi } from '@/services/api';

const DOCUMENT_TYPES = [
  { value: 'PRESCRIPTION', label: 'Prescription' },
  { value: 'LAB_REPORT', label: 'Lab / Diagnostic Report' },
  { value: 'DISCHARGE_SUMMARY', label: 'Discharge Summary' },
  { value: 'INSURANCE', label: 'Insurance / Claim Document' },
  { value: 'SCAN_XRAY', label: 'Scan / X-Ray / Imaging' },
  { value: 'OTHER', label: 'Other Medical Record' },
];

export default function DocumentsPage() {
  const { addToast } = useToast();
  const fileInputRef = useRef(null);

  const [documents, setDocuments] = useState([]);
  const [familyMembers, setFamilyMembers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterType, setFilterType] = useState('ALL');
  const [filterMember, setFilterMember] = useState('ALL');

  // Modals
  const [isUploadModalOpen, setIsUploadModalOpen] = useState(false);
  const [isDeleteModalOpen, setIsDeleteModalOpen] = useState(false);
  const [docToDelete, setDocToDelete] = useState(null);
  const [submitting, setSubmitting] = useState(false);
  const [downloadingId, setDownloadingId] = useState(null);

  // Upload Form
  const [selectedFile, setSelectedFile] = useState(null);
  const [formData, setFormData] = useState({
    title: '',
    documentType: 'PRESCRIPTION',
    description: '',
    familyMemberId: '',
  });

  const fetchData = async () => {
    try {
      setLoading(true);
      const [docRes, famRes] = await Promise.all([
        documentsApi.getAll().catch(() => ({ data: [] })),
        familyApi.getAll().catch(() => ({ data: [] })),
      ]);

      const docList = Array.isArray(docRes) ? docRes : (docRes.data || []);
      const famList = Array.isArray(famRes) ? famRes : (famRes.data || []);
      setDocuments(docList);
      setFamilyMembers(famList);
    } catch (err) {
      addToast(err.message || 'Failed to load documents', 'error');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const openUploadModal = () => {
    setSelectedFile(null);
    setFormData({
      title: '',
      documentType: 'PRESCRIPTION',
      description: '',
      familyMemberId: '',
    });
    setIsUploadModalOpen(true);
  };

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setSelectedFile(file);
      if (!formData.title) {
        setFormData(prev => ({
          ...prev,
          title: file.name.replace(/\.[^/.]+$/, '')
        }));
      }
    }
  };

  const handleUpload = async (e) => {
    e.preventDefault();
    if (!selectedFile) {
      addToast('Please select a file to upload', 'warning');
      return;
    }

    try {
      setSubmitting(true);
      const data = new FormData();
      data.append('file', selectedFile);
      if (formData.title) data.append('title', formData.title.trim());
      if (formData.documentType) data.append('documentType', formData.documentType);
      if (formData.description) data.append('description', formData.description.trim());
      if (formData.familyMemberId) data.append('familyMemberId', formData.familyMemberId);

      await documentsApi.upload(data);
      addToast('Document uploaded successfully', 'success');
      setIsUploadModalOpen(false);
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to upload document', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const handleDownload = async (doc) => {
    try {
      setDownloadingId(doc.id);
      const blob = await documentsApi.download(doc.id);
      
      const blobUrl = window.URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = blobUrl;
      link.download = doc.fileName || `${doc.title || 'document'}.pdf`;
      document.body.appendChild(link);
      link.click();
      link.remove();
      window.URL.revokeObjectURL(blobUrl);

      addToast(`Downloaded ${doc.title || 'document'}`, 'success');
    } catch (err) {
      addToast(err.message || 'Download failed', 'error');
    } finally {
      setDownloadingId(null);
    }
  };

  const confirmDelete = (doc) => {
    setDocToDelete(doc);
    setIsDeleteModalOpen(true);
  };

  const handleDelete = async () => {
    if (!docToDelete) return;
    try {
      setSubmitting(true);
      await documentsApi.delete(docToDelete.id);
      addToast('Document removed', 'success');
      setIsDeleteModalOpen(false);
      fetchData();
    } catch (err) {
      addToast(err.message || 'Failed to delete document', 'error');
    } finally {
      setSubmitting(false);
    }
  };

  const formatFileSize = (bytes) => {
    if (!bytes) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
  };

  // Filtered documents
  const filteredDocuments = documents.filter(doc => {
    const matchesSearch = doc.title?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.fileName?.toLowerCase().includes(searchQuery.toLowerCase()) ||
      doc.description?.toLowerCase().includes(searchQuery.toLowerCase());

    const matchesType = filterType === 'ALL' || doc.documentType === filterType;

    const matchesMember = filterMember === 'ALL'
      ? true
      : filterMember === 'SELF'
        ? !doc.familyMemberId
        : doc.familyMemberId === filterMember;

    return matchesSearch && matchesType && matchesMember;
  });

  return (
    <div className="space-y-6">
      {/* Top Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-900 tracking-tight">Medical Documents Vault</h1>
          <p className="text-sm text-slate-500 mt-1">
            Securely store and access prescriptions, diagnostic lab reports, and scan files
          </p>
        </div>
        <div className="flex items-center gap-3">
          <Button variant="outline" size="sm" onClick={fetchData} disabled={loading}>
            <RefreshCw className={`w-4 h-4 mr-2 ${loading ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          <Button size="sm" onClick={openUploadModal}>
            <Upload className="w-4 h-4 mr-2" />
            Upload Document
          </Button>
        </div>
      </div>

      {/* Filters Bar */}
      <Card>
        <CardContent className="p-4">
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
            <Input
              placeholder="Search documents..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              icon={Search}
            />

            <Select
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
              options={[
                { value: 'ALL', label: 'All Document Types' },
                ...DOCUMENT_TYPES
              ]}
            />

            <Select
              value={filterMember}
              onChange={(e) => setFilterMember(e.target.value)}
              options={[
                { value: 'ALL', label: 'All Family Members' },
                { value: 'SELF', label: 'Myself (Primary)' },
                ...familyMembers.map(m => ({ value: m.id, label: `${m.name} (${m.relationship})` }))
              ]}
            />
          </div>
        </CardContent>
      </Card>

      {/* Document Grid */}
      {loading ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {[1, 2, 3].map(i => (
            <Card key={i} className="animate-pulse p-6 space-y-3">
              <div className="h-6 bg-slate-200 rounded w-1/2"></div>
              <div className="h-4 bg-slate-100 rounded w-3/4"></div>
            </Card>
          ))}
        </div>
      ) : filteredDocuments.length === 0 ? (
        <Card className="text-center py-12">
          <CardContent className="space-y-4">
            <div className="w-12 h-12 rounded-full bg-teal-50 text-teal-600 flex items-center justify-center mx-auto">
              <FileText className="w-6 h-6" />
            </div>
            <div>
              <h3 className="text-base font-semibold text-slate-900">No documents found</h3>
              <p className="text-sm text-slate-500 max-w-sm mx-auto mt-1">
                {searchQuery || filterType !== 'ALL' || filterMember !== 'ALL'
                  ? 'No documents match your active search filters.'
                  : 'Upload your medical reports, test results, or doctor prescriptions.'}
              </p>
            </div>
            {!(searchQuery || filterType !== 'ALL' || filterMember !== 'ALL') && (
              <Button onClick={openUploadModal}>
                <Upload className="w-4 h-4 mr-2" />
                Upload First Document
              </Button>
            )}
          </CardContent>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
          {filteredDocuments.map(doc => {
            const memberName = familyMembers.find(f => f.id === doc.familyMemberId)?.name;
            const typeConfig = DOCUMENT_TYPES.find(t => t.value === doc.documentType);

            return (
              <Card key={doc.id} className="flex flex-col justify-between hover:border-slate-300 transition-all">
                <CardContent className="p-5 space-y-4">
                  <div className="flex items-start justify-between gap-3">
                    <div className="flex items-start gap-3">
                      <div className="w-10 h-10 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center shrink-0">
                        <FileText className="w-5 h-5" />
                      </div>
                      <div>
                        <h3 className="font-semibold text-slate-900 leading-snug">{doc.title || doc.fileName}</h3>
                        <p className="text-xs text-slate-500 font-mono mt-0.5">{doc.fileName}</p>
                      </div>
                    </div>
                  </div>

                  <div className="space-y-2 text-xs bg-slate-50 p-3 rounded-lg border border-slate-100">
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">Type:</span>
                      <span className="font-medium text-teal-800 bg-teal-50 px-2 py-0.5 rounded">
                        {typeConfig ? typeConfig.label : doc.documentType}
                      </span>
                    </div>

                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">File Size:</span>
                      <span className="font-mono text-slate-700">{formatFileSize(doc.fileSize)}</span>
                    </div>

                    {memberName && (
                      <div className="flex items-center justify-between">
                        <span className="text-slate-500">Patient:</span>
                        <span className="font-medium text-purple-700 bg-purple-50 px-2 py-0.5 rounded flex items-center gap-1">
                          <User className="w-3 h-3" />
                          {memberName}
                        </span>
                      </div>
                    )}
                  </div>

                  {doc.description && (
                    <p className="text-xs text-slate-500 line-clamp-2 italic">
                      "{doc.description}"
                    </p>
                  )}
                </CardContent>

                <div className="p-3 border-t border-slate-100 bg-slate-50/50 flex items-center justify-between">
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleDownload(doc)}
                    loading={downloadingId === doc.id}
                  >
                    <Download className="w-3.5 h-3.5 mr-1" />
                    Download
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="text-rose-600 hover:text-rose-700 hover:bg-rose-50"
                    onClick={() => confirmDelete(doc)}
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </Button>
                </div>
              </Card>
            );
          })}
        </div>
      )}

      {/* Upload Modal */}
      <Modal
        isOpen={isUploadModalOpen}
        onClose={() => !submitting && setIsUploadModalOpen(false)}
        title="Upload Medical Document"
        description="Select a file from your device and categorize it for quick reference."
        maxWidth="max-w-lg"
      >
        <form onSubmit={handleUpload} className="space-y-4">
          <div>
            <label className="text-xs font-semibold text-slate-700 block mb-1.5">
              Select Document File *
            </label>
            <div 
              onClick={() => fileInputRef.current?.click()}
              className="border-2 border-dashed border-slate-300 hover:border-teal-500 rounded-xl p-6 text-center cursor-pointer bg-slate-50 hover:bg-teal-50/20 transition-all"
            >
              <input
                type="file"
                ref={fileInputRef}
                onChange={handleFileChange}
                className="hidden"
                accept=".pdf,.png,.jpg,.jpeg,.doc,.docx"
              />
              <Upload className="w-8 h-8 text-teal-600 mx-auto mb-2" />
              {selectedFile ? (
                <div>
                  <p className="text-sm font-semibold text-slate-900">{selectedFile.name}</p>
                  <p className="text-xs text-slate-500">{formatFileSize(selectedFile.size)}</p>
                </div>
              ) : (
                <div>
                  <p className="text-sm font-medium text-slate-700">Click to browse file</p>
                  <p className="text-xs text-slate-400 mt-1">PDF, JPG, PNG, DOCX up to 25MB</p>
                </div>
              )}
            </div>
          </div>

          <Input
            label="Document Title"
            placeholder="e.g., Annual Blood Panel 2026"
            value={formData.title}
            onChange={(e) => setFormData({ ...formData, title: e.target.value })}
          />

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <Select
              label="Document Type"
              value={formData.documentType}
              onChange={(e) => setFormData({ ...formData, documentType: e.target.value })}
              options={DOCUMENT_TYPES}
            />

            <Select
              label="For Patient"
              value={formData.familyMemberId}
              onChange={(e) => setFormData({ ...formData, familyMemberId: e.target.value })}
              options={[
                { value: '', label: 'Myself (Primary User)' },
                ...familyMembers.map(m => ({ value: m.id, label: `${m.name} (${m.relationship})` }))
              ]}
            />
          </div>

          <Input
            label="Description / Notes"
            placeholder="e.g., Prescribed by Dr. Jenkins at City Clinic"
            value={formData.description}
            onChange={(e) => setFormData({ ...formData, description: e.target.value })}
          />

          <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
            <Button type="button" variant="outline" onClick={() => setIsUploadModalOpen(false)} disabled={submitting}>
              Cancel
            </Button>
            <Button type="submit" loading={submitting}>
              Upload Document
            </Button>
          </div>
        </form>
      </Modal>

      {/* Delete Confirmation Modal */}
      <Modal
        isOpen={isDeleteModalOpen}
        onClose={() => !submitting && setIsDeleteModalOpen(false)}
        title="Delete Document"
        description="Are you sure you want to permanently delete this document from the vault?"
        maxWidth="max-w-md"
      >
        <div className="flex items-center justify-end gap-3 pt-4">
          <Button variant="outline" onClick={() => setIsDeleteModalOpen(false)} disabled={submitting}>
            Cancel
          </Button>
          <Button variant="danger" onClick={handleDelete} loading={submitting}>
            Confirm Delete
          </Button>
        </div>
      </Modal>
    </div>
  );
}
