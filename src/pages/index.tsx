import { NextPage } from 'next'
import Head from 'next/head'

const Home: NextPage = () => {
  return (
    <>
      <Head>
        <title>LLM Platform - Personal AI Experience Platform</title>
        <meta name="description" content="Organize your AI interactions into topic-based experiences with custom AI personalities and intelligent agents." />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <link rel="icon" href="/favicon.ico" />
      </Head>

      <main className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
        <div className="container mx-auto px-4 py-16">
          <div className="text-center">
            <h1 className="text-6xl font-bold text-gray-900 mb-6">
              LLM Platform
            </h1>
            
            {/* Deployment Test Banner */}
            <div className="bg-green-100 border border-green-400 text-green-700 px-4 py-3 rounded mb-6 max-w-2xl mx-auto">
              <div className="flex items-center justify-center">
                <span className="text-2xl mr-2">🚀</span>
                <div>
                  <strong>Deployment Test #2 Successful!</strong>
                  <br />
                  <span className="text-sm">CI/CD Pipeline Working Perfectly! - {new Date().toLocaleString()}</span>
                </div>
              </div>
            </div>
            
            {/* Second Test Banner */}
            <div className="bg-blue-100 border border-blue-400 text-blue-700 px-4 py-3 rounded mb-6 max-w-2xl mx-auto">
              <div className="flex items-center justify-center">
                <span className="text-2xl mr-2">⚡</span>
                <div>
                  <strong>Automated Deployment Active!</strong>
                  <br />
                  <span className="text-sm">Ready for daily releases! - {new Date().toLocaleString()}</span>
                </div>
              </div>
            </div>
            <p className="text-xl text-gray-600 mb-8 max-w-3xl mx-auto">
              Organize your AI interactions into topic-based experiences with custom AI personalities, 
              system prompts, and intelligent agents that optimize your workspace over time.
            </p>
            
            <div className="flex justify-center space-x-4 mb-12">
              <button className="bg-blue-600 hover:bg-blue-700 text-white font-semibold py-3 px-6 rounded-lg transition-colors">
                Get Started
              </button>
              <button className="bg-gray-200 hover:bg-gray-300 text-gray-800 font-semibold py-3 px-6 rounded-lg transition-colors">
                Learn More
              </button>
            </div>

            <div className="grid md:grid-cols-3 gap-8 max-w-5xl mx-auto">
              <div className="bg-white p-6 rounded-lg shadow-md">
                <div className="text-blue-600 text-4xl mb-4">🚀</div>
                <h3 className="text-xl font-semibold mb-2">Multi-LLM Integration</h3>
                <p className="text-gray-600">
                  Seamlessly integrate ChatGPT, Claude, and Gemini with a unified interface.
                </p>
              </div>
              
              <div className="bg-white p-6 rounded-lg shadow-md">
                <div className="text-blue-600 text-4xl mb-4">🎭</div>
                <h3 className="text-xl font-semibold mb-2">Custom AI Personalities</h3>
                <p className="text-gray-600">
                  Create and customize AI personalities for different contexts and use cases.
                </p>
              </div>
              
              <div className="bg-white p-6 rounded-lg shadow-md">
                <div className="text-blue-600 text-4xl mb-4">🤖</div>
                <h3 className="text-xl font-semibold mb-2">Intelligent Agents</h3>
                <p className="text-gray-600">
                  AI-powered agents that monitor and optimize your workspace automatically.
                </p>
              </div>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}

export default Home
