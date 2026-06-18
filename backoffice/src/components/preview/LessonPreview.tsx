import type { Lesson } from '../../types';
import Dialog from '../ui/Dialog';
import Badge from '../ui/Badge';
import MarkdownRenderer from '../ui/MarkdownRenderer';
import { FileText, Code, HelpCircle, Video, File, ExternalLink, Globe, Copy, Check, BookOpen } from 'lucide-react';
import { useState } from 'react';

interface Props {
  lesson: Lesson;
  onHide: () => void;
}

const typeIcons: Record<string, React.ReactNode> = {
  theory: <BookOpen className="w-5 h-5" />,
  code: <Code className="w-5 h-5" />,
  quiz: <HelpCircle className="w-5 h-5" />,
};

function getYoutubeId(url: string): string | null {
  const m = url.match(/(?:youtube\.com\/embed\/|youtu\.be\/|youtube\.com\/watch\?v=)([a-zA-Z0-9_-]+)/);
  return m ? m[1] : null;
}

export default function LessonPreview({ lesson, onHide }: Props) {
  const [copied, setCopied] = useState(false);

  const resources = (() => {
    try { const r = JSON.parse(lesson.resources || '[]'); return Array.isArray(r) ? r : []; }
    catch { return []; }
  })();

  const resourceIcon = (type: string) => {
    switch (type) {
      case 'pdf': return <File className="w-4 h-4" />;
      case 'github': return <Globe className="w-4 h-4" />;
      default: return <ExternalLink className="w-4 h-4" />;
    }
  };

  const copyCode = () => {
    if (lesson.code_template) {
      navigator.clipboard.writeText(lesson.code_template);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    }
  };

  const youtubeId = lesson.video_url ? getYoutubeId(lesson.video_url) : null;

  return (
    <Dialog
      header={
        <div className="flex items-center gap-3">
          <span className="text-indigo-400">{typeIcons[lesson.lesson_type]}</span>
          <span>{lesson.title}</span>
          <Badge value={lesson.lesson_type} severity="info" className="text-[11px]" />
          <span className="text-xs text-gray-500">+{lesson.xp_reward} XP</span>
        </div>
      }
      visible
      onHide={onHide}
      width="740px"
    >
      <div className="max-h-[70vh] overflow-y-auto pr-1 space-y-5">
        {lesson.content && (
          <div className="bg-[var(--bg-card)] rounded-xl p-5 border border-[var(--border-subtle)]">
            <MarkdownRenderer content={lesson.content} />
          </div>
        )}

        {lesson.video_url && (
          <div>
            <h4 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2 flex items-center gap-2">
              <Video className="w-4 h-4 text-red-400" /> Video
            </h4>
            {youtubeId ? (
              <div className="aspect-video rounded-xl overflow-hidden bg-black">
                <iframe
                  src={`https://www.youtube.com/embed/${youtubeId}`}
                  className="w-full h-full"
                  allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
                  allowFullScreen
                  title="Lesson video"
                />
              </div>
            ) : (
              <video controls className="w-full rounded-xl" src={lesson.video_url}>
                Your browser does not support the video tag.
              </video>
            )}
          </div>
        )}

        {lesson.lesson_type === 'code' && lesson.code_template && (
          <div>
            <h4 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2 flex items-center gap-2">
              <Code className="w-4 h-4 text-cyan-400" /> Code Template
              {lesson.code_language && (
                <Badge value={lesson.code_language} severity="secondary" className="text-[10px]" />
              )}
              {lesson.has_editor && <Badge value="editor" severity="success" className="text-[10px]" />}
            </h4>
            <div className="relative group">
              <pre className="bg-[#0D1117] rounded-xl p-4 text-sm font-mono leading-relaxed overflow-auto max-h-64 text-gray-200 border border-gray-800">
                <code>{lesson.code_template}</code>
              </pre>
              <button
                onClick={copyCode}
                className="absolute top-2 right-2 p-1.5 rounded-md bg-gray-800/80 text-gray-400 hover:text-white hover:bg-gray-700 transition-colors opacity-0 group-hover:opacity-100"
                title="Copy code"
              >
                {copied ? <Check className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
              </button>
            </div>
          </div>
        )}

        {resources.length > 0 && (
          <div>
            <h4 className="text-xs font-semibold text-gray-500 uppercase tracking-wider mb-2 flex items-center gap-2">
              <FileText className="w-4 h-4 text-amber-400" /> Resources ({resources.length})
            </h4>
            <div className="space-y-2">
              {resources.map((r: any, i: number) => (
                <a
                  key={i}
                  href={r.url}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex items-center gap-3 p-3 rounded-lg bg-gray-800/50 border border-gray-700/50 hover:bg-gray-700/50 hover:border-gray-600 transition-colors"
                >
                  <span className="text-gray-400">{resourceIcon(r.type || 'link')}</span>
                  <span className="flex-1 text-sm text-gray-200">{r.title || r.url}</span>
                  <span className="text-xs text-gray-500 uppercase">{r.type || 'link'}</span>
                  <ExternalLink className="w-3.5 h-3.5 text-gray-500" />
                </a>
              ))}
            </div>
          </div>
        )}

        {!lesson.content && !lesson.video_url && !lesson.code_template && resources.length === 0 && (
          <div className="text-center py-12 text-gray-500">
            <FileText className="w-12 h-12 mx-auto mb-3 opacity-30" />
            <p>No content to preview</p>
          </div>
        )}
      </div>
    </Dialog>
  );
}
