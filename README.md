# ai-assets

跨机器复用的 AI agent 资产：skills、模板与配置。

## skills/

| skill | 用途 |
|---|---|
| [`skills/wiki/`](skills/wiki/) | LLM Wiki 知识库维护与问答：ingest（消化资料）/ query（问答）/ lint（健康检查）/ crystallize（对话结晶）。模式出处：[karpathy/llm-wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) |

### 安装 wiki skill 到一台新机器

ZCode（及兼容 agent）按以下优先级发现 skill：项目级 `<项目>/.agents/skills/`、用户级 `~/.agents/skills/`。安装即复制：

```bash
git clone git@github.com:SCUT-Mida/ai-assets.git
mkdir -p ~/.agents/skills
cp -r ai-assets/skills/wiki ~/.agents/skills/wiki
```

- **用户级安装**（`~/.agents/skills/wiki/`）：所有知识库实例通用，推荐。
- **项目级安装**（`<知识库>/.agents/skills/wiki/`）：仅该知识库可用。注意：知识库目录内只放知识库本体（raw/ + wiki/ + AGENTS.md + git），skill 建议放用户级，保持知识库纯净。

### 新建一个知识库实例

一个 LLM Wiki 知识库 = 三层结构的目录 + git 仓库：

```
<你的知识库>/
├── AGENTS.md        # schema：结构、页面格式、三大工作流、维护纪律
├── raw/             # 原始资料（用户写入，LLM 只读）；assets/ 放附件
└── wiki/            # LLM 维护：index.md, log.md, overview.md, purpose.md,
                     #   conventions.md, sources/, entities/, concepts/, analyses/
```

参考实例与 AGENTS.md 写法：见仓库维护者的知识库（或向仓库提交你的实例模板）。
