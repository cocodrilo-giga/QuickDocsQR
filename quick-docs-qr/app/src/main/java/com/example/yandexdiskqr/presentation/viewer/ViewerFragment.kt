package com.example.yandexdiskqr.presentation.viewer

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.navigation.fragment.navArgs
import com.example.yandexdiskqr.databinding.FragmentViewerBinding
import com.google.android.material.snackbar.Snackbar
import dagger.hilt.android.AndroidEntryPoint

@AndroidEntryPoint
class ViewerFragment : Fragment() {
    private var _binding: FragmentViewerBinding? = null
    private val binding get() = _binding!!
    
    private val viewModel: ViewerViewModel by viewModels()
    private val args: ViewerFragmentArgs by navArgs()
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentViewerBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        
        viewModel.loadFolder(args.folderPath)
        observeViewModel()
    }

    private fun observeViewModel() {
        viewModel.folder.observe(viewLifecycleOwner) { folder ->
            // Update UI with folder contents
        }

        viewModel.error.observe(viewLifecycleOwner) { error ->
            error?.let {
                Snackbar.make(binding.root, it, Snackbar.LENGTH_LONG).show()
            }
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        _binding = null
    }
}
